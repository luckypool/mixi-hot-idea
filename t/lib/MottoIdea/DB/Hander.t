use strict;
use warnings;
use utf8;
use Test::More;
use Test::MockObject;

use Data::Dumper;

my $class;
BEGIN {
    use_ok($class='MottoIdea::DB::Handler');
}

subtest q/basic/ => sub {
    Test::MockObject->new->fake_module($class,
        'get_dbh', sub { return 'fake_db';}
    );
    my $model = $class->new(role=>'m');
    ok $model, q/new ok/;
    ok $model->db, q/db ok/;
    is $model->db, 'fake_db', q/is fake_db/;
};

done_testing;
