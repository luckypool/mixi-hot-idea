package MottoIdea::DB::Handler::Idea;
use strict;
use warnings;
use utf8;

use parent qw/MottoIdea::DB::Handler/;
use MottoIdea::DB::Config;
use MottoIdea::DB::Skinny::Idea;
use MottoIdea::DB::Skinny::Idea::Schema;

use Params::Validate;

# --
# override parent class method
sub get_dbh {
    my ($self, $user) = @_;
    my $config = MottoIdea::DB::Config->new;
    return MottoIdea::DB::Skinny::Idea->new(+{
        dsn => $config->db_idea,
        username=>$user,
        connect_options => {
            mysql_enable_utf8 => 1,
        }
    });
}

1;
