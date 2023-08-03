

init-dirs:
	cat required_dirs.txt | xargs mkdir -p


pipeline-voter-data:
	xfile --config config/extract_van_data.yaml --delimiter ',' --map voters static_data/ohio_rvht.csv \
	> temp_data/voter_data.json


pipeline-voting-history:
	xfile --config config/extract_van_data.yaml --delimiter ',' --map voting_data static_data/ohio_rvht.csv \
	> temp_data/voting_history_data.json



