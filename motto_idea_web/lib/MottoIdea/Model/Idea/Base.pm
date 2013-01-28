package MottoIdea::Model::Idea::Base;
use strict;
use warnings;
use utf8;

use parent qw/Class::Accessor::Fast/;

use Date::Calc qw/Localtime/;
use Params::Validate;
use MottoIdea::DB::Handler::Idea;

use constant {
    DEFAULT_LIMIT        => 30,
    DEFAULT_OFFSET       => 0,
    DEFAULT_ORDER        => 'DESC',
    DEFAULT_TIME_TO_FIND => 60 * 60 * 24,
};

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

sub update_by_id {
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
            SELECT * FROM %s WHERE %s BETWEEN :from AND :to ORDER BY %s %s LIMIT %s OFFSET %s
        },
        $params,
        [ $self->table, map { $params->{$_} } qw/find_type find_type order limit offset/]
    )->all;
    return unless $row;
    return [ map {$_->get_columns} @$row ];
}

sub exists {
    my $self = shift;
    my $row = $self->select_by_id(@_);
    return defined $row ? 1 : 0;
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
