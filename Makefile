conf:
	@export $(shell grep -v '^#' params.conf | xargs) && bash ./scripts/generate.sh conf
sql:
	@export $(shell grep -v '^#' params.conf | xargs) && bash ./scripts/generate.sh sql