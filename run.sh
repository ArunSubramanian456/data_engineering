#!/bin/bash

set -e

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# sync the venv to uv.lock: the project (editable) + the dev group, plus any extra groups passed in.
# --locked fails if pyproject.toml and uv.lock disagree (run `uv lock` or use `add`).
# (example) ./run.sh install --group dbt
function install {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
    fi
    uv sync --locked "$@"
    # install the git hook (.git/hooks/pre-commit) so checks run on every `git commit`.
    # Skipped in CI: GitHub Actions sets CI=true, and CI only needs `pre-commit run` (lint:ci).
    if [[ -z "$CI" ]]; then
        uv run --locked pre-commit install
    fi
}

# add a dependency to pyproject.toml, update uv.lock and install it.
# (example) ./run.sh add pandas                    -> runtime dep of src/
# (example) ./run.sh add --group dbt dbt-core      -> tool group, installed with `install --group dbt`
function add {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
    fi
    uv add "$@"
}

# remove a dependency from pyproject.toml and uv.lock.
# (example) ./run.sh remove --group dbt dbt-duckdb
function remove {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
    fi
    uv remove "$@"
}

# run linting, formatting, and other static code quality tools during local development
function lint {
    export PRE_COMMIT_HOME=~/.cache/pre-commit
    if [[ -n "$VIRTUAL_ENV" ]]; then
        export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
        pre-commit run --all-files
    else
        uv run pre-commit run --all-files
    fi
}

# same as `lint` but with any special considerations for CI
function lint:ci {
    # We skip no-commit-to-branch since that blocks commits to `main`.
    # All merged PRs are commits to `main` so this must be disabled.
    export PRE_COMMIT_HOME=~/.cache/pre-commit
    if [[ -n "$VIRTUAL_ENV" ]]; then
        export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
        SKIP=no-commit-to-branch pre-commit run --all-files
    else
        SKIP=no-commit-to-branch uv run pre-commit run --all-files
    fi
}

# # execute tests that are not marked as `slow`
# function test:quick {
#     run-tests -m "not slow" ${@:-"$THIS_DIR/tests/"}
# }

# run python from the activated venv if there is one (CI, test:wheel-locally), else from the project venv via uv
function py {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        python "$@"
    else
        uv run --locked python "$@"
    fi
}

# execute tests against the installed package; assumes the wheel is already installed
function test:ci {
    INSTALLED_PKG_DIR="$(py -c 'import data_engineering; print(data_engineering.__path__[0])')"
    # in CI, we must calculate the coverage for the installed package, not the src/ folder
    COVERAGE_DIR="$INSTALLED_PKG_DIR" run-tests
}

# (example) ./run.sh test tests/test_states_info.py::test__slow_add
function run-tests {
    local REPORTS_DIR="$THIS_DIR/test-reports"
    # start from a clean report dir so no stale HTML pages survive from a previous run
    rm -rf "$REPORTS_DIR"
    mkdir -p "$REPORTS_DIR"
    PYTEST_EXIT_STATUS=0
    # write every report straight into test-reports/ (no mv afterwards)
    COVERAGE_FILE="$REPORTS_DIR/.coverage" py -m pytest ${@:-"$THIS_DIR/tests/"} \
        --cov "${COVERAGE_DIR:-$THIS_DIR/src}" \
        --cov-report "html:$REPORTS_DIR/htmlcov" \
        --cov-report term \
        --cov-report "xml:$REPORTS_DIR/coverage.xml" \
        --junit-xml "$REPORTS_DIR/report.xml" || ((PYTEST_EXIT_STATUS+=$?))
    return $PYTEST_EXIT_STATUS
}

function test:wheel-locally {
    deactivate 2>/dev/null || true
    rm -rf test-env 2>/dev/null || true
    uv venv test-env
    source test-env/bin/activate
    clean 2>/dev/null || true
    build
    uv pip install ./dist/*.whl pytest pytest-cov
    test:ci
    deactivate || true
    rm -rf test-env 2>/dev/null || true
}

# serve the html test coverage report on localhost:8000
function serve-coverage-report {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
    fi
    uv run python -m http.server --directory "$THIS_DIR/test-reports/htmlcov/" 8000
}

# build a wheel and sdist from the Python source code
function build {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
    fi
    uv build --sdist --wheel "$THIS_DIR/"
}

# function release:test {
#     lint
#     clean
#     build
#     publish:test
# }

# function release:prod {
#     release:test
#     publish:prod
# }

# function publish:test {
#     try-load-dotenv || true
#     twine upload dist/* \
#         --repository testpypi \
#         --username=__token__ \
#         --password="$TEST_PYPI_TOKEN"
# }

# function publish:prod {
#     try-load-dotenv || true
#     twine upload dist/* \
#         --repository pypi \
#         --username=__token__ \
#         --password="$PROD_PYPI_TOKEN"
# }

# remove all files generated by tests, builds, or operating this codebase
function clean {
    rm -rf dist build coverage.xml test-reports .pytest_cache .ruff_cache .ty_cache .coverage || true
    find . \
      -type d \
      \( \
        -name "*cache*" \
        -o -name "*.dist-info" \
        -o -name "*.egg-info" \
        -o -name "*htmlcov" \
      \) \
      -not -path "*env/*" \
      -exec rm -r {} + 2>/dev/null || true

    find . \
      -type f \
      -name "*.pyc" \
      -not -path "*/venv/*" \
      -not -path "*/test-env/*" \
      -exec rm -f {} + 2>/dev/null || true
}

# export the contents of .env as environment variables
function try-load-dotenv {
    if [ ! -f "$THIS_DIR/.env" ]; then
        echo "no .env file found"
        return 1
    fi

    set -o allexport
    source "$THIS_DIR/.env"
    set +o allexport
}

# print all functions in this file
function help {
    echo "Usage:$0 <task> <args>"
    echo "Available tasks:"
    compgen -A function | cat -n
}

TIMEFORMAT="Task completed in %3lR"
time ${@:-help}
