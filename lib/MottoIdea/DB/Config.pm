package MottoIdea::DB::Config;
use strict;
use warnings;
use utf8;

use parent qw/Class::Accessor::Fast/;
__PACKAGE__->mk_ro_accessors(qw/
    db_idea
/);

use constant {
    DB_IDEA => 'DBI:mysql:mottoidea',
};

sub new {
    my $class = shift;
    my $self = {
        db_idea => DB_IDEA,
    };
    return bless $self, $class;
}

1;
