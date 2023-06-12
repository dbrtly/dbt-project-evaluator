#!/bin/bash
VENV="venv/bin/activate"

if [[ ! -f $VENV ]]
then
    python3 -m venv venv
    . $VENV

    pip install --upgrade pip setuptools

    if [[ $1 == "duckdb" ]]
    then
        pip install "dbt-$1"
    else
        pip install --pre "dbt-$1"
    fi
fi

. $VENV

cd integration_tests
if [[ ! -e ~/.dbt/profiles.yml ]]; then
    mkdir -p ~/.dbt
    cp ci/sample.profiles.yml ~/.dbt/profiles.yml
fi

# used for now while we still test against 1.5 on DuckdDB
if [[ $1 == "duckdb" ]] ; then
    cp models/marts/metrics.yml.dbt_metrics models/marts/metrics.yml
fi

# tests with the first project
dbt deps --target $1 || exit 1
dbt build -x --target $1 --full-refresh || exit 1

# test with the second project
cd ../integration_tests_2
dbt deps --target $1 || exit 1
dbt seed --full-refresh --target $1 || exit 1
dbt run -x --target $1 --full-refresh || exit 1