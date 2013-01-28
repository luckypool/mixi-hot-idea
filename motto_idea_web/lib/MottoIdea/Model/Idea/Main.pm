package MottoIdea::Model::Idea::Main;
use strict;
use warnings;
use utf8;

use parent qw/MottoIdea::Model::Idea::Base/;

use constant {
    TABLE_MAIN => 'idea_main',
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

sub update_point_by_id {
    my $self = shift;
    my $params = Params::Validate::validate(@_, {
        idea_id   => { regex => qr/^\d+$/ },
        positive_point => { regex => qr/^\d+$/ },
        negative_point => { regex => qr/^\d+$/ },
    });
    return $self->master->update(
        $self->table, {
            positive_point => $params->{positive_point},
            negative_point => $params->{negative_point},
        },
        { idea_id   => $params->{idea_id} },
    );
}

sub update_statsu_by_id {
    my $self = shift;
    my $params = Params::Validate::validate(@_, {
        idea_id   => { regex => qr/^\d+$/ },
        status_id => { regex => qr/^\d+$/ },
    });
    return $self->master->update(
        $self->table,
        { status_id => $params->{status_id} },
        { idea_id   => $params->{idea_id} },
    );
}

1;
