#!/bin/bash
make_database_yaml.pl -d "dbi:mysql:dbname=mottoidea" -u root -o ./t/fixture/schema.yaml
