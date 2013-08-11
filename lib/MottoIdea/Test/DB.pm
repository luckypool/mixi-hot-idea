package MottoIdea::Test::DB;
use strict;
use warnings;
use utf8;

use UNIVERSAL::require;
use MottoIdea::Test::mysqld;

use Test::MockObject;

sub import {
    my ($parent, $name) = @_;
    my $db_name = (split /_/, $name)[1];
    $db_name = ucfirst(lc $db_name);
    my $class_name = 'MottoIdea::DB::Skinny::'.$db_name;
    $class_name->require;
    my $db = MottoIdea::Test::mysqld->get_db($class_name, $name);
    Test::MockObject->fake_module($class_name,
        new => sub {
            my $self = shift;
            my ($param) = @_;
            my @dsn_param = split /:/, $param->{dsn};
            $db->do("use $dsn_param[2]");
            return $db;
        }
    );
}

1;
