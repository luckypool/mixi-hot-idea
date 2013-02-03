#!/usr/env perl
use utf8;
use strict;
use warnings;
use 5.010;

use Encode;

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use List::MoreUtils qw/all apply indexes/;
use Date::Calc qw/Date_to_Time Today_and_Now Mktime/;

use MottoIdea::Model::Idea::Main;
use MottoIdea::Model::Idea::Rank;

#DEBUG
use Data::Dumper;
use Devel::Peek qw/Dump/;
# use MottoIdea::Test::DB qw/DB_IDEA/;

my $main_model   = MottoIdea::Model::Idea::Main->new;
my $rank_model   = MottoIdea::Model::Idea::Rank->new;
my $params = {
    idea_id     => int rand 100,
    title       => Encode::encode('utf8','あああああ'),
    status_id   => 0,
    category_id => 0,
    positive_point => 0,
    negative_point => 0,
};

say Dump $params->{title};
my $ret = $main_model->insert($params);
say Dump $ret->{title};

say 'success';

