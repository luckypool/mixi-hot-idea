use strict;
use warnings;
use utf8;

use Test::More;
use Test::Deep;
use Test::MockTime;

use MottoIdea::Test::DB qw/DB_IDEA/;

# for debug
use Devel::Peek qw/Dump/;
use Data::Dumper;

my $class;
BEGIN {
    use_ok($class='MottoIdea::Model::Idea::Status');
}

my $obj = new_ok $class;

sub create_dummy_data {
    my $id = int rand 1000000;
    return {
        idea_id        => $id,
        has_response   => int rand 2,
        current_status => int rand 5,
        last_status    => int rand 5,
    };
}

subtest q/crud/ => sub {
    my $now = time();
    Test::MockTime::set_fixed_time($now);

    my $dummy_data1 = create_dummy_data();

    subtest q/insert/ => sub {
        my $row = $obj->insert($dummy_data1);
        my $expected = {%$dummy_data1};
        $expected->{inserted_at} = $obj->time_to_mysqldatetime($now);
        cmp_deeply $row, $expected;
    };

    subtest q/select/ => sub {
        my $expected = {%$dummy_data1};
        $expected->{inserted_at} = $obj->time_to_mysqldatetime($now);
        $expected->{updated_at} = $obj->time_to_mysqldatetime();

        my $row = $obj->select_by_id(idea_id=>$expected->{idea_id});
        ok $row;
        cmp_deeply $expected, $row;
    };

    subtest q/update/ => sub {
        my $update_time = $now+600;
        Test::MockTime::set_fixed_time($update_time);
        my $expected = {%$dummy_data1};
        $expected->{has_response}   = !$expected->{has_response};
        $expected->{last_status}    = $expected->{current_status};
        $expected->{current_status} = 1;
        $expected->{inserted_at}    = $obj->time_to_mysqldatetime($now);
        $expected->{updated_at}     = $obj->time_to_mysqldatetime($update_time);
        ok $obj->update_by_id(
            idea_id => $expected->{idea_id},
            has_response   => $expected->{has_response},
            current_status => $expected->{current_status},
            last_status    => $expected->{last_status},
        );
        my $row = $obj->select_by_id(idea_id=>$expected->{idea_id});
        cmp_deeply $expected, $row;
    };

    Test::MockTime::restore_time();

    subtest q/delete/ => sub {
        my $expected = {%$dummy_data1};
        is $obj->exists(idea_id=>$expected->{idea_id}), 1;
        ok $obj->delete_by_id(idea_id=>$expected->{idea_id});
        is $obj->exists(idea_id=>$expected->{idea_id}), 0;
    };
};

subtest q/find/ => sub {
    ok 1;
    my @dummy_data_list = map { create_dummy_data() } (1..50);
    my @expected_list;
    my $current = time - 60 * 60 * 50;

    # THE WORLD!!!
    Test::MockTime::set_fixed_time($current);

    # WRYYYYYYY!!!!!
    for my $dummy (@dummy_data_list){
        my $expected = {%$dummy};
        $expected->{inserted_at} = $obj->time_to_mysqldatetime($current);
        unshift @expected_list, $expected;
        $obj->insert($dummy);
        $current = $current + 60 * 60;
        Test::MockTime::set_fixed_time($current);
    };

    # 時は動き出す・・・！
    # default では 24 時間前までのものをDESCで最大30件とってくる
    my $rows = $obj->find();

    map {
        $_->{updated_at}=$obj->time_to_mysqldatetime();
        my $got = shift @$rows;
        cmp_deeply $_, $got, "ok $_->{inserted_at}";
    } splice @expected_list, 0, 24;
    is_deeply $rows, [], 'length ok';

    Test::MockTime::restore_time();
};

done_testing;
