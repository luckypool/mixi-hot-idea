package MottoIdea::Model::Idea::Rank;
use strict;
use warnings;
use utf8;

use parent qw/MottoIdea::Model::Idea::Base/;
use Date::Calc qw/Localtime/;

use Params::Validate;

use constant {
    TABLE_RANK => 'ranking_info',
    DEFAULT_LIMIT        => 30,
    DEFAULT_OFFSET       => 0,
    DEFAULT_ORDER        => 'DESC',
    DEFAULT_GT_TENDENCY  => 144,
    DEFAULT_TIME_TO_FIND => 60 * 60 * 24,
};

sub table {
    return TABLE_RANK;
};

sub validate_basic_params {
    my $self = shift;
    return Params::Validate::validate(@_, {
        idea_id       => { regex => qr/^\d+$/ },
        tendency      => { regex => qr/^\d+$/, default => 0 },
        current_rank  => { regex => qr/^\d+$/ },
        last_rank     => { regex => qr/^\d+$/ },
    });
}

sub get_update_params {
    my $self = shift;
    my ($params) = @_;
    return {
        map { $_ => $params->{$_} } qw/tendency current_rank last_rank/
    };
}

sub select_last_updated_datetime_by_id {
    my $self = shift;
    my $row = $self->select_by_id(@_);
    return unless $row;
    return $row->{updated_at};
}

sub select_tendency_by_id {
    my $self = shift;
    my $row = $self->select_by_id(@_);
    return unless $row;
    return $row->{tendency};
}

sub select_current_rank_by_id {
    my $self = shift;
    my $row = $self->select_by_id(@_);
    return unless $row;
    return $row->{current_rank};
}

sub find {
    my $self = shift;
    my $params = Params::Validate::validate(@_, {
        from   => { regex => qr/^\d+$/, default => $self->time_to_mysqldatetime(time-DEFAULT_TIME_TO_FIND()) },
        to     => { regex => qr/^\d+$/, default => $self->time_to_mysqldatetime(time) },
        offset => { regex => qr/^\d+$/, default => DEFAULT_OFFSET() },
        limit  => { regex => qr/^\d+$/, default => DEFAULT_LIMIT() },
        order  => { regex => qr/^(DESC|ASC)$/, default => DEFAULT_ORDER() },
        find_type => { regex => qr/^(updated_at|inserted_at)$/, default => 'inserted_at' },
    });

    my $row = $self->slave->search_named(
        q{
            SELECT idea_id,tendency,current_rank,last_rank FROM %s WHERE %s BETWEEN :from AND :to ORDER BY %s %s LIMIT %s OFFSET %s
        },
        $params,
        [ $self->table, map { $params->{$_} } qw/find_type find_type order limit offset/]
    )->all;
    return unless $row;
    return [ map {$_->get_columns} @$row ];
}

sub find_recent_top {
    my $self = shift;
    my $params = Params::Validate::validate(@_, {
        from   => { regex => qr/^\d+$/, default => $self->time_to_mysqldatetime(time-DEFAULT_TIME_TO_FIND()*7) },
        to     => { regex => qr/^\d+$/, default => $self->time_to_mysqldatetime(time) },
        offset => { regex => qr/^\d+$/, default => DEFAULT_OFFSET() },
        limit  => { regex => qr/^\d+$/, default => DEFAULT_LIMIT() },
        order  => { regex => qr/^(DESC|ASC)$/, default => DEFAULT_ORDER() },
        find_type => { regex => qr/^(updated_at|inserted_at)$/, default => 'updated_at' },
        gt_tendency => { regex => qr/^\d+$/, default => DEFAULT_GT_TENDENCY() },
    });

    my $row = $self->slave->search_named(
        q{
            SELECT idea_id,tendency FROM %s WHERE tendency > %s AND %s BETWEEN :from AND :to ORDER BY tendency %s LIMIT %s OFFSET %s
        },
        $params,
        [ $self->table, map { $params->{$_} } qw/gt_tendency find_type order limit offset/]
    )->all;
    return unless $row;
    return [ map {$_->get_columns} @$row ];
}




# --
# Utils
sub time_to_mysqldatetime {
    my $self = shift;
    my ($time) = @_;
    my @datetime = defined $time ? Localtime($time) : split '', (0 x 6);
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d", @datetime);
};

1;
