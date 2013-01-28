package MottoIdea::DB::Skinny::Idea::Schema;
use strict;
use warnings;
use utf8;

use DBIx::Skinny::Schema;
use DateTime;
use DateTime::Format::Strptime;
use DateTime::Format::MySQL;

sub pre_insert_hook {
    my ( $class, $args ) = @_;
    $args->{inserted_at} = DateTime->now( time_zone => 'Asia/Tokyo' );
}

sub pre_update_hook {
    my ( $class, $args ) = @_;
    $args->{updated_at} = DateTime->now( time_zone => 'Asia/Tokyo' );
}

install_inflate_rule '^.+_at$' => callback {
    inflate {
        my $value = shift;
        my $dt = DateTime::Format::Strptime->new(
            pattern => '%Y-%m-%d %H:%M:%S',
            time_zone => container('timezone'),
        )->parse_datetime($value);
        return DateTime->from_object( object => $dt );
    };
    deflate {
        my $value = shift;
        return DateTime::Format::MySQL->format_datetime($value);
    };
};

install_utf8_columns qw/title/;
install_table main_info => schema {
    pk 'idea_id';
    columns qw/idea_id title status_id category_id count positive_point negative_point updated_at inserted_at/;
    trigger pre_insert => \&pre_insert_hook;
    trigger pre_update => \&pre_update_hook;
};

install_table ranking_info => schema {
    pk 'idea_id';
    columns qw/idea_id tendency current_rank last_rank inserted_at updated_at/;
    trigger pre_insert => \&pre_insert_hook;
    trigger pre_update => \&pre_update_hook;
};

1;
