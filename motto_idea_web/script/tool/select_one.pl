#!/usr/env perl
use strict;
use warnings;
use utf8;
use 5.010;
use Encode;

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use List::MoreUtils qw/all apply indexes/;
use Date::Calc qw/Date_to_Time Today_and_Now Mktime/;

use MottoIdea::Model::Idea::Main;
use MottoIdea::Model::Idea::Rank;

#DEBUG
# use Data::Dumper;
use Devel::Peek qw/Dump/;

# use MottoIdea::Test::DB qw/DB_IDEA/;

my $main_model   = MottoIdea::Model::Idea::Main->new;
my $rank_model   = MottoIdea::Model::Idea::Rank->new;

my $found_data = $main_model->select_by_id(idea_id=>59);
say Encode::encode ('utf8',$found_data->{title});

