package MottoIdea::Model::Idea::Main;
use strict;
use warnings;
use utf8;

use parent qw/MottoIdea::Model::Idea::Base/;
use Date::Calc qw/Localtime/;

use constant {
    TABLE_MAIN => 'main_info',
    DEFAULT_LIMIT        => 30,
    DEFAULT_OFFSET       => 0,
    DEFAULT_ORDER        => 'DESC',
    DEFAULT_TIME_TO_FIND => 60 * 60 * 24 * 7,
};

sub table {
    return TABLE_MAIN;
};

sub validate_basic_params {
    my $self = shift;
    return Params::Validate::validate(@_, {
        idea_id        => { regex => qr/^\d+$/ },
        title          => { type  => Params::Validate::SCALAR },
        status_id      => { regex => qr/^\d+$/ },
        category_id    => { regex => qr/^\d+$/ },
        positive_point => { regex => qr/^\d+$/ },
        negative_point => { regex => qr/^\d+$/ },
    });
}

sub get_update_params {
    my $self = shift;
    my ($params) = @_;
    return {
        map { $_ => $params->{$_} } qw/title status_id category_id positive_point negative_point/
    };
}

sub bulk_insert {
    my $self = shift;
    my $param = Params::Validate::validate(@_, {
        data => 1,
    });
    my @insert_param_list = map {
        +{ $self->validate_basic_params($_) }
    } @{$param->{data}};
    return $self->master->bulk_insert($self->table, \@insert_param_list);
}

sub find {
    my $self = shift;
    my $params = Params::Validate::validate(@_, {
        from   => { regex => qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/, default => $self->time_to_mysqldatetime(time-DEFAULT_TIME_TO_FIND()) },
        to     => { regex => qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/, default => $self->time_to_mysqldatetime(time) },
        offset => { regex => qr/^\d+$/, default => DEFAULT_OFFSET() },
        limit  => { regex => qr/^\d+$/, default => DEFAULT_LIMIT() },
        order  => { regex => qr/^(DESC|ASC)$/, default => DEFAULT_ORDER() },
        find_type => { regex => qr/^(updated_at|inserted_at)$/, default => 'inserted_at' },
    });

    my $row = $self->slave->search_named(
        q{
            SELECT * FROM %s WHERE %s BETWEEN :from AND :to ORDER BY %s %s LIMIT %s OFFSET %s
        },
        $params,
        [ $self->table, map { $params->{$_} } qw/find_type find_type order limit offset/]
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
