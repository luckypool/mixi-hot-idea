use strict;
use warnings;
use utf8;
use Test::More;

my $class;
BEGIN {
    use_ok($class='MottoIdea::DB::Config');
}

subtest qw/basic/ => sub {
    new_ok $class;
};

done_testing;
