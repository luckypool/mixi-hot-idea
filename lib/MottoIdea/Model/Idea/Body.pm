package MottoIdea::Model::Idea::Body;
use strict;
use warnings;
use utf8;

use parent qw/MottoIdea::Model::Idea::Base/;

use constant {
    TABLE_BODY => 'body_info',
};

sub table {
    return TABLE_BODY;
};

sub validate_basic_params {
    my $self = shift;
    return Params::Validate::validate(@_, {
        idea_id => { regex => qr/^\d+$/ },
        body    => { type  => Params::Validate::SCALAR },
    });
}

sub get_update_params {
    my $self = shift;
    my ($params) = @_;
    return {
        body => $params->{body}
    };
}

1;
