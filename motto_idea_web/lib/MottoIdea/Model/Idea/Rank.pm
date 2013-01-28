package MottoIdea::Model::Idea::Rank;
use strict;
use warnings;
use utf8;

use parent qw/MottoIdea::Model::Idea::Base/;

use Params::Validate;

use constant {
    TABLE_RANK => 'rank',
};

sub table {
    return TABLE_RANK;
};

sub validate_basic_params {
    my $self = shift;
    return Params::Validate::validate(@_, {
        idea_id          => { regex => qr/^\d+$/ },
        remarkable_point => { regex => qr/^\d+$/ },
        current_rank     => { regex => qr/^\d+$/ },
        last_rank        => { regex => qr/^\d+$/ },
    });
}

sub get_update_params {
    my $self = shift;
    my ($params) = @_;
    return {
        map { $_ => $params->{$_} } qw/remarkable_point current_rank last_rank/
    };
}

1;
