

init-dirs:
	cat required_dirs.txt | xargs mkdir -p


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
