package MottoIdea::Web::jsonrpc::Main;
use Mojo::Base 'MojoX::JSON::RPC::Service';
use Params::Validate;
use MottoIdea::Model::Idea::Main;

__PACKAGE__->register_rpc_method_names( 'lookup' );

sub lookup {
    my $self = shift;
    my $params = Params::Validate::validate(@_, {
        id => { regex => qr/^\d+$/ },
    });
    my $model = MottoIdea::Model::Idea::Main->new;
    my $find_row = $model->select_by_id(
        idea_id => $params->{id},
    );
    return $find_row;
}

1;
