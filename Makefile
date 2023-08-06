

#### Makefile for civiX voter data analysis platform

	#_______________________________________________________________________
	#
	# 
	#_______________________________________________________________________
	#


init-dirs:
	cat required_dirs.txt | xargs mkdir -p


gen-dba-script:
	warp --py --template-file=template_files/mkdbauser.sql.tpl --params=name:cvxdba,description:Administrator,pw:notobvious \
	> temp_sql/create_dba_role.sql

dblogin:
	export PGPASSWORD=$$CVX_DBA_PASSWORD && psql -h localhost -U cvxdba -d civix


clean:
	rm -f tempdata/*
	rm -f temp_scripts/*
	rm -f temp_sql/*


db-generate-dim-data:
	cat /dev/null > temp_sql/dimension_data.sql

	dgenr8 --plugin-module dim_day_generator --sql --schema public --dim-table dim_date_day --columns id value label \
	>> temp_sql/dimension_data.sql

	dgenr8 --plugin-module dim_month_generator --sql --schema public --dim-table dim_date_month --columns id value label \
	>> temp_sql/dimension_data.sql
	
	dgenr8 --plugin-module dim_year_generator --sql --schema public --dim-table dim_date_year --columns id value label \
	>> temp_sql/dimension_data.sql

	dgenr8 --plugin-module dim_election_type_generator --sql --schema public --dim-table dim_election_type --columns id value label \
	>> temp_sql/dimension_data.sql

	dgenr8 --plugin-module ref_party_generator --sql --schema public --dim-table ref_party --columns id value label \
	>> temp_sql/dimension_data.sql


db-create-tables:	
	export PGPASSWORD=$$CVX_DBA_PASSWORD && psql -h localhost -U cvxdba -d civix -f sql/cvx_db_extensions.sql
	export PGPASSWORD=$$CVX_DBA_PASSWORD && psql -h localhost -U cvxdba -d civix -f sql/civix_ddl.sql


db-populate-dimensions:
	export PGPASSWORD=$$CVX_DBA_PASSWORD && psql -h localhost -U cvxdba -d civix -f temp_sql/dimension_data.sql


db-purge-dimensions:
	export PGPASSWORD=$$CVX_DBA_PASSWORD && psql -h localhost -U cvxdba -d civix \
	--file=sql/truncate_dimension_tables.sql


db-purge-facts:
	export PGPASSWORD=$$CVX_DBA_PASSWORD && psql -h localhost -U cvxdba -d civix \
	--file=sql/truncate_fact_tables.sql

db-drop-tables:
	export PGPASSWORD=$$CVX_DBA_PASSWORD && psql -h localhost -U cvxdba -d civix \
	--file=sql/drop_all_tables.sql


db-purge-olap: db-purge-dimensions db-purge-facts


prep-voter-data:
	xfile --config config/extract_van_data.yaml --delimiter ',' --map voters static_data/ohio_rvht.csv \
	> temp_data/voter_data.json


prep-voting-history-data:
	xfile --config config/extract_van_data.yaml --delimiter ',' --map voting_history static_data/ohio_rvht.csv \
	> temp_data/voting_history_data.json

merge-recordsets:
	scripts/subrec2field.py --parent temp_data/voter_data.json --child temp_data/voting_history_data.json \
	--field history > temp_data/voter_dataset.json


ingest-voter-data:

	$(eval CHUNK_SIZE=5)
	#_______________________________________________________________________
	#
	# clean up any chunkfiles from previous runs 
	#_______________________________________________________________________
	#

	rm temp_data/chunked_*

	#_______________________________________________________________________
	#
	# chunk the voter-data JSON records for parallel ingest
	#_______________________________________________________________________
	#

	chunkr --records temp_data/voter_dataset.json --chunks $(CHUNK_SIZE) --pfx chunked_voter_data --ext jsonl -t temp_data \
	> temp_data/chunked_voter_data_files.txt

	#_______________________________________________________________________
	#
	# loop over the emitted list of chunkfiles 
	# to generate our ingestion commands
	#_______________________________________________________________________
	#

	loopr -p -t --listfile temp_data/chunked_voter_data_files.txt --vartoken % \
	--cmd-string 'ngst --config config/ingest_van_data.yaml --target db --datafile temp_data/% --params=record_type:voter' \
	> temp_data/voter_data_ingest_commands.txt

	#_______________________________________________________________________
	#
	# generate the list of output files 
	#_______________________________________________________________________
	#

	countup --from 1 --to $(CHUNK_SIZE) > temp_data/chunk_index.txt

	loopr -p -t --listfile temp_data/chunk_index.txt --vartoken % \
	--cmd-string 'voter_id_map_chunk_%.jsonl' > temp_data/voter_data_ingest_outfiles.txt

	#_______________________________________________________________________
	#
	# generate our ingestion command manifest
	#_______________________________________________________________________
	#

	tuplegen --delim ',' --listfiles=temp_data/voter_data_ingest_commands.txt,temp_data/voter_data_ingest_outfiles.txt \
	| tuple2json --delim ',' --keys=command,outfile > temp_data/voter_data_ingest_manifest.jsonl

	#_______________________________________________________________________
	#
	# populate the shell script
	#_______________________________________________________________________
	#

	cp template_files/shell_script_core.sh.tpl temp_scripts/ingest_voter_data.sh

	loopr -p -j --listfile temp_data/voter_data_ingest_manifest.jsonl \
	--cmd-string '{command} > {outfile} &' >> temp_scripts/ingest_voter_data.sh

	echo 'wait' >> temp_scripts/ingest_voter_data.sh

	#_______________________________________________________________________
	#
	# set permissions and execute
	#_______________________________________________________________________
	#

	chmod u+x temp_scripts/ingest_voter_data.sh
	time temp_scripts/ingest_voter_data.sh


pipeline-voter-data: prep-voter-data prep-voting-history-data merge-recordsets ingest-voter-data


test-ingest: ingest-voter-data