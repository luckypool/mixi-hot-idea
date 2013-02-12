#!/usr/env perl
use utf8;
use strict;
use warnings;
use 5.010;

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use List::MoreUtils qw/all apply indexes/;
use Date::Calc qw/Date_to_Time Today_and_Now Mktime/;

use WWW::Mechanize;
use WWW::Mechanize::DecodedContent;
use Web::Query;

use MottoIdea::Model::Idea::Main;
use MottoIdea::Model::Idea::Rank;

#DEBUG
use Data::Dumper;
# use MottoIdea::Test::DB qw/DB_IDEA/;


# --
# common objects
# --
my $conf = do "$FindBin::Bin/../../config.pl" or die;
my $search_idea_url = $conf->{search_idea_url};
my $mech = WWW::Mechanize->new;
my $main_model   = MottoIdea::Model::Idea::Main->new;
my $rank_model   = MottoIdea::Model::Idea::Rank->new;

my @today_and_now = Today_and_Now();

say sprintf("called  at -- %04d/%02d/%02d %02d:%02d:%02d\n", Today_and_Now());
main();
say sprintf("succeed at -- %04d/%02d/%02d %02d:%02d:%02d\n", Today_and_Now());

# --
# main functions
# --
sub main {
    my $current_data_list =  get_current_data_list();
    for my $current_data (@$current_data_list){
        my $current_rank = $current_data->{rank};
        delete $current_data->{rank};
        my $current_id = $current_data->{idea_id};
        my $main_params = {
            %$current_data,
        };
        my $rank_params = {
            idea_id      => $current_data->{idea_id},
            tendency     => int 1 * 60 * 60 * 24 / 600,
            current_rank => $current_rank,
            last_rank    => 0,
        };
        my $last_main_data = $main_model->select_by_id(idea_id=>$current_id);
        my $last_rank_data = $rank_model->select_by_id(idea_id=>$current_id);

        unless($last_main_data){
            # insert
            say "  insert $main_params->{idea_id}";
            $main_model->insert($main_params);
            $rank_model->insert($rank_params);
        } else {
            # update
            say "  update $main_params->{idea_id}";
            my $is_not_changed = all { $last_main_data->{$_} eq $current_data->{$_} } qw/positive_point negative_point/;
            my $plus_count = $is_not_changed ? 0 : calc_count($last_main_data, $current_data);
            my $diff_sec = calc_diff_sec($last_main_data);
            my $last_tendency = $last_rank_data->{tendency};
            my $plus_tendency = $plus_count*60*60*24/600;
            $rank_params->{tendency}  = int(($last_tendency+$plus_tendency)*60*60*24/(60*60*24+$diff_sec));
            $rank_params->{last_rank} = $last_rank_data->{current_rank};
            $rank_params->{current_rank} = $current_rank;
            $rank_model->update($rank_params);
            $main_model->update($main_params);
        }
    }
}

# --
# helper functions
# --
sub calc_diff_sec {
    my ($rank_data) = @_;
    my $last_datetime = datetime_to_epoch($rank_data->{updated_at});
    $last_datetime = datetime_to_epoch($rank_data->{inserted_at}) unless $last_datetime;
    return Date_to_Time(Today_and_Now()) - $last_datetime;
}

sub datetime_to_epoch {
    my $datetime = shift;
    my ($year, $month, $day, $hour, $min, $sec) = map {
        int $_
    } $datetime =~ /^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})$/;
    return unless $year;
    return Date_to_Time($year, $month, $day, $hour, $min, $sec);
}

sub calc_count {
    my ($last, $current) = @_;
    return ($current->{negative_point} - $last->{negative_point}) + ($current->{positive_point} - $last->{positive_point});
}

sub get_current_data_list {
    my $q = __get_web_query();
    $q = $q->find('.entryList01');
    my $idea_list_query = $q->last()->find('li');
    return $idea_list_query->map(sub {
        my ($i, $elem) = @_;
        return +{
            rank        => $i+1,
            idea_id     => __get_id_from_atag($elem->find('a')->attr('href')),
            title       => $elem->find('.idea')->text(),
            status_id   => __status_of($elem->find('.status')->text()),
            category_id => __category_of($elem->find('.category')->text()),
            positive_point => $elem->find('.positive')->text(),
            negative_point => $elem->find('.negative')->text(),
        };
    });
}

sub __get_web_query {
    $mech->get('http://mixi.jp/');
    $mech->submit_form(
        fields => {
            email => $conf->{login_mail},
            password => $conf->{login_password},
        },
    );
    $mech->get($search_idea_url);
    return Web::Query->new_from_html($mech->decoded_content);

    # open IN, '<:utf8', 'hoge.html' or die;
    # my $html;
    # {
    #     local $/ = undef; # <FILE>を配列じゃなくて一括で受け取る
    #     $html = <IN>;
    # }
    # close IN;
    # my $q = Web::Query->new_from_html($html);
}

sub __get_id_from_atag {
    my $href = shift;
    if($href =~ m/(\d+)$/){
        return $1;
    }
}

sub __status_of {
    my $str = shift;
    my $status_of = {
        '要望中'      => 1,
        '検討中'      => 2,
        '実装中'      => 3,
        '実装済'      => 4,
        '見送り'      => 5,
        '見送り/重複' => 6,
    };
    return $status_of->{$str};
}

sub __category_of {
    my $str = shift;
    my $category_of = {
        '日記'                         => 1,
        'コミュニティ'                 => 2,
        'モバイル版'                   => 3,
        'レビュー'                     => 4,
        'メッセージ'                   => 5,
        '足あと（訪問者）'             => 6,
        'お気に入り'                   => 7,
        'ニュース'                     => 8,
        'プレミアム'                   => 9,
        'フォト'                       => 10,
        'ミュージック'                 => 11,
        '友人'                         => 12,
        'つぶやき'                     => 13,
        'ゲーム'                       => 14,
        'mixiページ'                   => 15,
        'mixiモール（ショッピング）'   => 16,
        'チェック'                     => 17,
        'チェックイン'                 => 18,
        'スマートフォン版'             => 19,
        'iPhoneアプリ'                 => 20,
        'Androidアプリ'                => 21,
        'パソコン版'                   => 22,
        'カレンダー'                   => 23,
        '同級生・同僚'                 => 24,
        '機能要望'                     => 25,
        'プロフィール'                 => 26,
        'mixiパーク'                   => 27,
        'アクセスブロック'             => 28,
        '友人を探す'                   => 29,
        'コメント/イイネ'              => 30,
        '動画'                         => 31,
        'mixiバースデー'               => 32,
        '3DS版'                        => 33,
        '検索機能'                     => 34,
        'mixiポイント'                 => 35,
        '新着お知らせ枠'               => 36,
        '友人の更新情報(タイムライン)' => 37,
        '新着お知らせ枠(イイネ・コメント通知)' => 38,
        'mixi新規登録'                 => 39,
        'メルマガ'                     => 40,
        'その他'                       => 99,
    };
    return $category_of->{$str};
}

