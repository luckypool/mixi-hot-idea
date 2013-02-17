package MottoIdea::Web;
use Mojo::Base 'Mojolicious';
use MottoIdea::Web::jsonrpc::Main;
use MottoIdea::Web::jsonrpc::Body;
use MottoIdea::Web::jsonrpc::Rank;

sub startup {
    my $self = shift;
    my $r = $self->routes;

    $r->get('/')->to('root#home');

    $self->plugin(
        'json_rpc_dispatcher',
        services => {
            '/api/rank/rpc.json' => MottoIdea::Web::jsonrpc::Rank->new,
        },
        exception_handler => sub {
             my ( $dispatcher, $err, $m ) = @_;
             # $dispatcher is the dispatcher Mojolicious::Controller object
             # $err is $@ received from the exception
             # $m is the MojoX::JSON::RPC::Dispatcher::Method object to be returned.
             return $m->invalid_params;
        }
    );

    $self->plugin(
        'json_rpc_dispatcher',
        services => {
            '/api/body/rpc.json' => MottoIdea::Web::jsonrpc::Body->new,
        },
        exception_handler => sub {
             my ( $dispatcher, $err, $m ) = @_;
             return $m->invalid_params;
        }
    );

    $self->plugin(
        'json_rpc_dispatcher',
        services => {
            '/api/main/rpc.json' => MottoIdea::Web::jsonrpc::Main->new,
        },
        exception_handler => sub {
             my ( $dispatcher, $err, $m ) = @_;
             return $m->invalid_params;
        }
    );

}

1;
