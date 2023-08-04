

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

ingest-voter-data:
	cat temp_data/voter_data.json | ngst --config config/ingest_van_data.yaml --target db --params=record_type:voter 
	# > temp_data/voter_id_map.jsonl

pipeline-voter-data: prep-voter-data ingest-voter-data


pipeline-voting-history:
	xfile --config config/extract_van_data.yaml --delimiter ',' --map voting_history static_data/ohio_rvht.csv \
	> temp_data/voting_history_data.json

	cat temp_data/voting_history_data.json | ngst --config config/ingest_van_data.yaml --target db \
	--params=record_type:voting_history > temp_data/voter_id_map.jsonl
