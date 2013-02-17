package MottoIdea::Web::Root;
use Mojo::Base 'Mojolicious::Controller';

sub home {
    my $self = shift;
    $self->render(
        footer_text => 'footer text',
    );
}

1;
