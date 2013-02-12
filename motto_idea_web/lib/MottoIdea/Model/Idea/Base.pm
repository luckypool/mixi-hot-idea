package MottoIdea::Model::Idea::Base;
use strict;
use warnings;
use utf8;

use parent qw/Class::Accessor::Fast/;

use Params::Validate;
use MottoIdea::DB::Handler::Idea;

__PACKAGE__->mk_accessors(qw/master slave/);

sub new {
    my $class = shift;
    my $self = {
        master => MottoIdea::DB::Handler::Idea->new(role=>'m')->db,
        slave  => MottoIdea::DB::Handler::Idea->new(role=>'s')->db,
    };
    return bless $self, $class;
}

# --
# common functions
sub insert {
    my $self = shift;
    my $params = $self->validate_basic_params(@_);
    return $self->master->insert($self->table, $params)->get_columns;
}

sub replace {
    my $self = shift;
    my $params = $self->validate_basic_params(@_);
    return $self->master->replace($self->table, $params)->get_columns;
}

sub select_by_id {
    my $self = shift;
    my $params = Params::Validate::validate(@_, {
        idea_id   => { regex => qr/^\d+$/ },
    });
    my $row = $self->slave->search($self->table, {
        idea_id => $params->{idea_id},
    })->first;
    return unless $row;
    return $row->get_columns;
}

sub update {
    my $self = shift;
    my $params = $self->validate_basic_params(@_);
    return $self->master->update(
        $self->table,
        $self->get_update_params($params),
        { idea_id   => $params->{idea_id} },
    );
}

sub delete_by_id {
    my $self = shift;
    my $params = Params::Validate::validate(@_, {
        idea_id   => { regex => qr/^\d+$/ },
    });
    return $self->master->delete($self->table, {
        idea_id => $params->{idea_id},
    });
}

sub exists {
    my $self = shift;
    my $row = $self->select_by_id(@_);
    return defined $row ? 1 : 0;
}

1;
