use strict;
use warnings;
use utf8;
use Test::More;

my $class;
BEGIN {
    use_ok($class='MottoIdea::DB::Handler::Idea');
}

subtest q/basic/ => sub {
    my $model = $class->new(role=>'m');
    ok $model;
};

done_testing;
