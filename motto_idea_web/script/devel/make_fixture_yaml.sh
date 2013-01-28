#!/bin/bash

error="  need option : -t tablename"

# --- arguments ---
if [ $# -lt 1 ];then
    echo ${error}
    exit 1
fi

opt=$1
shift

if [ ${opt} != '-t' ];then
    echo ${error}
    exit 1
fi

table=$1
make_fixture_yaml.pl -d 'dbi:mysql:dbname=mottoidea' -u root -t ${table} -n id -o ./t/fixture/DB_IDEA/${table}.yaml
echo "  done! => ./t/fixture/DB_IDEA/${table}.yaml"

