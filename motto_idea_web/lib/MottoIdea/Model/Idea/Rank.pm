package MottoIdea::Model::Idea::Rank;
use strict;
use warnings;
use utf8;

use parent qw/MottoIdea::Model::Idea::Base/;

use Params::Validate;

use constant {
    TABLE_RANK => 'ranking_info',
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
    return $row->get_columns->{updated_at};
}

sub select_tendency_by_id {
    my $self = shift;
    my $row = $self->select_by_id(@_);
    return unless $row;
    return $row->get_columns->{tendency};
}

sub select_current_rank_by_id {
    my $self = shift;
    my $row = $self->select_by_id(@_);
    return unless $row;
    return $row->get_columns->{current_rank};
}

1;
