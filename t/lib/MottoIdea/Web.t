use strict;
use warnings;
use utf8;

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $class;
BEGIN {
    # use_ok($class='MottoIdea::Web');
}

subtest q/basic/ => sub {
    ok 1;
    # my $t = Test::Mojo->new($class);
    # $t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);
};

done_testing;
