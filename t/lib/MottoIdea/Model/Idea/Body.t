use strict;
use warnings;
use utf8;

use Test::More;
use Test::Deep;
use Test::MockTime;

use MottoIdea::Test::DB qw/DB_IDEA/;
use Encode;

# for debug
use Devel::Peek qw/Dump/;
use Data::Dumper;

my $class;
BEGIN {
    use_ok($class='MottoIdea::Model::Idea::Body');
}

my $obj = new_ok $class;

sub create_dummy_data {
    my $id = int rand 1000000;
    return {
        idea_id => $id,
        body    => 'ほげぽよhoge',
    };
}

subtest q/crud/ => sub {
    my $now = time();
    my $dummy_data1 = create_dummy_data();

    subtest q/insert/ => sub {
        my $row = $obj->insert($dummy_data1);
        my $expected = {%$dummy_data1};
        cmp_deeply $row, $expected;
    };

    subtest q/select/ => sub {
        my $expected = {%$dummy_data1};
        my $row = $obj->select_by_id(idea_id=>$expected->{idea_id});
        ok $row;
        cmp_deeply $expected, $row;
    };

    subtest q/update/ => sub {
        my $expected = {%$dummy_data1};
        $expected->{body} = 'fugaぽよ';
        ok $obj->update(
            idea_id => $expected->{idea_id},
            body    => $expected->{body},
        );
        my $row = $obj->select_by_id(idea_id=>$expected->{idea_id});
        cmp_deeply $expected, $row;
    };

    subtest q/delete/ => sub {
        my $expected = {%$dummy_data1};
        is $obj->exists(idea_id=>$expected->{idea_id}), 1;
        ok $obj->delete_by_id(idea_id=>$expected->{idea_id});
        is $obj->exists(idea_id=>$expected->{idea_id}), 0;
    };
};

done_testing;
