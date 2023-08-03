

init-dirs:
	cat required_dirs.txt | xargs mkdir -p


clean:
	rm -f tempdata/*
	rm -f temp_scripts/*
	rm -f temp_sql/*


dblogin:
	export PGPASSWORD=$$CVX_DB_PASSWORD && psql -w -U cvxdba --port=5432 --host=localhost -d civix


db-generate-dim-data:
	cat /dev/null > temp_sql/dimension_data.sql

	dgenr8 --plugin-module dim_day_generator --sql --schema public --dim-table dim_date_day --columns id value label \
	>> temp_sql/dimension_data.sql

	dgenr8 --plugin-module dim_month_generator --sql --schema public --dim-table dim_date_month --columns id value label \
	>> temp_sql/dimension_data.sql
	
	dgenr8 --plugin-module dim_year_generator --sql --schema public --dim-table dim_date_year --columns id value label \
	>> temp_sql/dimension_data.sql

	dgenr8 --plugin-module dim_permit_type_generator --sql --schema public --dim-table dim_permit_type --columns id value label \
	>> temp_sql/dimension_data.sql


db-create-tables:
	export PGPASSWORD=$$CVX_DB_PASSWORD && psql -w -d $$CVX_DB -h $$CVX_DB_HOST -p $$CVX_DB_PORT -U $$CVX_DB_USER -f sql/CVX_db_extensions.sql
	export PGPASSWORD=$$CVX_DB_PASSWORD && psql -w -d $$CVX_DB -h $$CVX_DB_HOST -p $$CVX_DB_PORT -U $$CVX_DB_USER -f sql/lex.sql


db-populate-dimensions:
	export PGPASSWORD=$$CVX_DB_PASSWORD && psql -w -U $$CVX_DB_USER -d $$CVX_DB -h $$CVX_DB_HOST -p $$CVX_DB_PORT --file=temp_sql/dimension_data.sql


db-purge-dimensions:
	export PGPASSWORD=$$CVX_DB_PASSWORD && psql -w -U $$CVX_DB_USER -d $$CVX_DB -h $$CVX_DB_HOST -p $$CVX_DB_PORT \
	--file=sql/truncate_dimension_tables.sql


db-purge-facts:
	export PGPASSWORD=$$CVX_DB_PASSWORD && psql -w -U $$CVX_DB_USER -d $$CVX_DB -h $$CVX_DB_HOST -p $$CVX_DB_PORT \
	--file=sql/truncate_fact_tables.sql


db-purge-olap: db-purge-dimensions db-purge-facts


pipeline-voter-data:
	xfile --config config/extract_van_data.yaml --delimiter ',' --map voters static_data/ohio_rvht.csv \
	> temp_data/voter_data.json

	cat temp_data/voter_data.json | ngst --config config/ingest_van_data.yaml --target db --params=record_type:voter \
	> temp_data/voter_id_map.jsonl


pipeline-voting-history:
	xfile --config config/extract_van_data.yaml --delimiter ',' --map voting_history static_data/ohio_rvht.csv \
	> temp_data/voting_history_data.json

	cat temp_data/voting_history_data.json | ngst --config config/ingest_van_data.yaml --target db \
	--params=record_type:voting_history > temp_data/voter_id_map.jsonl
