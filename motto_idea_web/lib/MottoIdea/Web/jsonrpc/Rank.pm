package MottoIdea::Web::jsonrpc::Rank;
use Mojo::Base 'MojoX::JSON::RPC::Service';
use Params::Validate;
use MottoIdea::Model::Idea::Rank;

__PACKAGE__->register_rpc_method_names( 'find' );

sub find {
    my $self = shift;
    my $params = Params::Validate::validate(@_, {
        limit  => { regex => qr/^\d+$/, default => 30 },
        offset => { regex => qr/^\d+$/, default => 0 },
        order  => { regex => qr/^(DESC|ASC)$/, default => 'DESC' },
        gt_tendency => { regex => qr/^\d+$/, default => 144 },
    });
    my $model = MottoIdea::Model::Idea::Rank->new;
    return $model->find_recent_top(
        limit  => $params->{limit},
        offset => $params->{offset},
        order  => $params->{order},
        gt_tendency => $params->{gt_tendency},
    );
}

1;
