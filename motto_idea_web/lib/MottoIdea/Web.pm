package MottoIdea::Web;
use Mojo::Base 'Mojolicious';
use MottoIdea::DB;

# This method will run once at server start
sub startup {
    my $self = shift;

    my $config = $self->plugin('Config', { file => 'mottoidea.conf' });
    $self->attr( db => sub { MottoIdea::DB->new( $config->{db} ) } );

    my $r = $self->routes;
    $r->get('/')->to('root#index');
    $r->post('/')->to('root#post');
    $r->route('/paste/:id')->to('root#entry');
}

1;
