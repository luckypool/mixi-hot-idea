#!/usr/env perl
use utf8;
use strict;
use warnings;
use 5.010;

use List::MoreUtils qw/all/;

use WWW::Mechanize;
use WWW::Mechanize::DecodedContent;
use Web::Query;

use MottoIdea::Model::Idea::Main;
use MottoIdea::Model::Idea::Rank;
use MottoIdea::Model::Idea::Status;

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

# my $conf = do q(./config.pl) or die;
#
# my $search_idea_url = q{http://mixi.jp/search_idea.pl?category_id=0&status_id=99&keyword=&order=2&ignore_mikan};
#
# my $mech = WWW::Mechanize->new;
# $mech->get('http://mixi.jp/');
# $mech->submit_form(
#     fields => {
#         email => $conf->{login_mail},
#         password => $conf->{login_password},
#     },
# );
# $mech->get($search_idea_url);
# my $q = Web::Query->new_from_html($mech->decoded_content);

open IN, '<:utf8', 'hoge.html' or die;
my $html;
{
    local $/ = undef; # <FILE>を配列じゃなくて一括で受け取る
    $html = <IN>;
}
my $q = Web::Query->new_from_html($html);


$q = $q->find('.entryList01');
my $idea_list_query = $q->last()->find('li');

my $list = $idea_list_query->map(sub {
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
my $status_model = MottoIdea::Model::Idea::Status->new;

for(@$list){
    my $rank = $_->{rank};
    delete $_->{rank};
    my $exists = $main_model->select_by_id(idea_id=>$_->{idea_id});
    my $main_params = $_;
    my $rank_params = {
        idea_id => $_->{idea_id},
        remarkable_point => 1,
        current_rank => $rank,
        last_rank => 0,
    };
    my $status_params = {
        idea_id => $_->{idea_id},
        has_response => 0,
        current_status => $_->{status_id},
        last_status    => 0,
    };
    unless($exists){
        $main_model->insert($main_params);
        $rank_model->insert($rank_params);
        $status_model->insert($status_params);
    }
    my $is_same = all { $exists->{$_} eq $main_params->{$_} } qw/positive_point negative_point status_id/;
    unless($is_same){
        $main_model->update_by_id($main_params);

        $rank_params->{last_rank} = $rank_params->{current_rank};
        $rank_params->{current_rank} = $rank;
        $rank_params->{remarkable_point} = 0 if $rank_params->{current_rank} eq 0;

        $rank_model->update_by_id($rank_params);

        $status_model->update_by_id($status_params);
    }
}

