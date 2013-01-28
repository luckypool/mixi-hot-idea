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

1;
