conf:
	@export $(shell grep -v '^#' params.env | xargs) && bash ./scripts/generate.sh conf
sql:
	@export $(shell grep -v '^#' params.env | xargs) && bash ./scripts/generate.sh sql