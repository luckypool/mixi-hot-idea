package MottoIdea::Model::Idea::Status;
use strict;
use warnings;
use utf8;

use parent qw/MottoIdea::Model::Idea::Base/;

use Params::Validate;

use constant {
    TABLE_STATUS => 'status',
};

sub table {
    return TABLE_STATUS;
};

sub validate_basic_params {
    my $self = shift;
    return Params::Validate::validate(@_, {
        idea_id        => { regex => qr/^\d+$/ },
        has_response   => { regex => qr/^\d+$/ },
        current_status => { regex => qr/^\d+$/ },
        last_status    => { regex => qr/^\d+$/ },
    });
}

sub get_update_params {
    my $self = shift;
    my ($params) = @_;
    return {
        map { $_ => $params->{$_} } qw/has_response current_status last_status/
    };
}

sub update_if_status_has_changed {
    my $self = shift;
    my $params = $self->validate_basic_params(@_);
    my $current_row = $self->select_by_id(idea_id=>$params->{idea_id});
    return if $current_row->{current_status} eq $params->{current_status};
    return $self->update_by_id($params);
}

1;
