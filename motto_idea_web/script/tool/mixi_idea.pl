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

my $status_of = {
    '要望中'      => 1,
    '検討中'      => 2,
    '実装中'      => 3,
    '実装済'      => 4,
    '見送り'      => 5,
    '見送り/重複' => 6,
};

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
    '友人の更新情報'               => 37,
    '赤文字・運営者からのお知らせ' => 38,
    'mixi新規登録'                 => 39,
    'メルマガ'                     => 40,
    'その他'                       => 99,
};

sub get_id {
    my $href = shift;
    if($href =~ m/(\d+)$/){
        return $1;
    }
}

my $conf = do "$FindBin::Bin/../../config.pl" or die;
my $search_idea_url = q{http://mixi.jp/search_idea.pl?category_id=0&status_id=99&keyword=&order=2&ignore_mikan};
my $mech = WWW::Mechanize->new;
$mech->get('http://mixi.jp/');
$mech->submit_form(
    fields => {
        email => $conf->{login_mail},
        password => $conf->{login_password},
    },
);
$mech->get($search_idea_url);
my $q = Web::Query->new_from_html($mech->decoded_content);

# open IN, '<:utf8', 'hoge.html' or die;
# my $html;
# {
#     local $/ = undef; # <FILE>を配列じゃなくて一括で受け取る
#     $html = <IN>;
# }
# close IN;
# my $q = Web::Query->new_from_html($html);


$q = $q->find('.entryList01');
my $idea_list_query = $q->last()->find('li');

my $current_data_list = $idea_list_query->map(sub {
    my ($i, $elem) = @_;
    return +{
        rank        => $i+1,
        idea_id     => get_id($elem->find('a')->attr('href')),
        title       => $elem->find('.idea')->text(),
        status_id   => $status_of->{$elem->find('.status')->text()},
        category_id => $category_of->{$elem->find('.category')->text()},
        positive_point => $elem->find('.positive')->text(),
        negative_point => $elem->find('.negative')->text(),
    };
});

my $main_model   = MottoIdea::Model::Idea::Main->new;
my $rank_model   = MottoIdea::Model::Idea::Rank->new;

my $found_data_list = $main_model->find();
my $found_data_href = {
    map { $_->{idea_id} => $_ } @$found_data_list
};

for my $current_data (@$current_data_list){
    my $current_rank = $current_data->{rank};
    delete $current_data->{rank};

    my $main_params = {
        %$current_data,
    };
    my $rank_params = {
        idea_id      => $current_data->{idea_id},
        tendency     => int 1 * 60 * 60 * 24 / 600,
        current_rank => $current_rank,
        last_rank    => 0,
    };

    my $found_data = $found_data_href->{$current_data->{idea_id}};
    if(not defined $found_data){
        $main_model->replace($main_params);
        $rank_model->replace($rank_params);
        next;
    }

    my $is_not_changed = all { $found_data->{$_} eq $current_data->{$_} } qw/positive_point negative_point/;
    my $plus_count = $is_not_changed ? 0 : calc_count($found_data, $current_data);
    my $current_tendency = $rank_model->select_tendency_by_id(idea_id=>$current_data->{idea_id});
    my $diff_sec = calc_diff_sec(map { $found_data->{$_} } qw/updated_at inserted_at/);

    $rank_params->{tendency}  = ($current_tendency + int $plus_count ) * 60 * 60 * 24 / $diff_sec;
    $rank_params->{last_rank} = $rank_model->select_current_rank_by_id(idea_id=>$current_data->{idea_id});
    $rank_params->{current_rank} = $current_rank;
    $rank_model->update($rank_params);
    $main_model->update($main_params);
}

sub calc_diff_sec {
    my ($updated_at, $inserted_at) = @_;
    my $diff_sec = defined datetime_to_epoch($updated_at)
                   ? Date_to_Time(Today_and_Now()) - datetime_to_epoch($updated_at)
                   : Date_to_Time(Today_and_Now()) - datetime_to_epoch($inserted_at);
    return $diff_sec;
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

say 'success';
