# Execute the "targets" in this file with `make <target>` e.g., `make test`.
#
# You can also run multiple in sequence, e.g. `make clean lint test serve-coverage-report`

build:
	bash run.sh build

clean:
	bash run.sh clean

help:
	bash run.sh help

# e.g. `make install ARGS="--group dbt"`
install:
	bash run.sh install $(ARGS)

# e.g. `make add ARGS="--group dbt dbt-core"`
add:
	bash run.sh add $(ARGS)

# e.g. `make remove ARGS="--group dbt dbt-duckdb"`
remove:
	bash run.sh remove $(ARGS)

lint:
	bash run.sh lint

lint-ci:
	bash run.sh lint:ci

# publish-prod:
# 	bash run.sh publish:prod

# publish-test:
# 	bash run.sh publish:test

# release-prod:
# 	bash run.sh release:prod

# release-test:
# 	bash run.sh release:test

serve-coverage-report:
	bash run.sh serve-coverage-report

test-ci:
	bash run.sh test:ci

# test-quick:
# 	bash run.sh test:quick

test:
	bash run.sh run-tests

test-wheel-locally:
	bash run.sh test:wheel-locally
