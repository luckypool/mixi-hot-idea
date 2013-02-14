#!/usr/env perl
use utf8;
use strict;
use warnings;
use 5.010;

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Date::Calc qw/Date_to_Time Today_and_Now Mktime/;

use WWW::Mechanize;
use WWW::Mechanize::DecodedContent;
use Web::Query;

use MottoIdea::Model::Idea::Main;
use MottoIdea::Model::Idea::Body;

#DEBUG
use Data::Dumper;
use MottoIdea::Test::DB qw/DB_IDEA/;

# --
# common objects
# --
my $conf = do "$FindBin::Bin/../../config.pl" or die;
my $search_idea_url = $conf->{search_idea_url};
my $mech = WWW::Mechanize->new;
$mech->get('http://mixi.jp/');
$mech->submit_form(
    fields => {
        email => $conf->{login_mail},
        password => $conf->{login_password},
    },
);
my $main_model = MottoIdea::Model::Idea::Main->new;
my $body_model = MottoIdea::Model::Idea::Body->new;

say sprintf("called  at -- %04d/%02d/%02d %02d:%02d:%02d\n", Today_and_Now());
main();
say sprintf("succeed at -- %04d/%02d/%02d %02d:%02d:%02d\n", Today_and_Now());

# --
# main functions
# --
sub main {
    my $found_list = $main_model->find(
        from => $main_model->time_to_mysqldatetime(time-60*60*24),
        to   => $main_model->time_to_mysqldatetime(time),
        limit => 1000,
        find_type => 'inserted_at'
    );

    for my $id (map{$_->{idea_id}} @$found_list){
        my $body =  get_body_by_id($id);
        say $id;
        say $body;
        $body_model->replace(
            idea_id => $id,
            body    => $body,
        );
    }
}

# --
# helper functions
# --
sub get_body_by_id {
    my $idea_id = shift;
    return unless $idea_id;
    my $view_idea_url = "http://mixi.jp/view_idea.pl?id=$idea_id";
    $mech->get($view_idea_url);
    my $q = Web::Query->new_from_html($mech->decoded_content);
    return $q->find('ul.editContents')->find('li')->filter(sub{
        my ($i, $elem) = @_;
        return 0 if $i ne 1;
        return 1;
    })->find('dd')->text;
}

