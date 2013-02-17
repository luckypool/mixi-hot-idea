package MottoIdea::Web::jsonrpc::Rank;
use Mojo::Base 'MojoX::JSON::RPC::Service';
use Params::Validate;
use MottoIdea::Model::Idea::Rank;

use Data::Dumper;

__PACKAGE__->register_rpc_method_names( 'find' );

# SELECT idea_id, tendency
# FROM ranking_info
# WHERE tendency >144
# AND updated_at
# BETWEEN  '2013-02-11 12:30:00'
# AND  '2013-02-12 12:31:00'
# ORDER BY idea_id DESC

sub find {
    my $self = shift;
    my $params = Params::Validate::validate(@_, {
        limit  => { regex => qr/^\d+$/, default => 30 },
        offset => { regex => qr/^\d+$/, default => 0 },
        order  => { regex => qr/^(DESC|ASC)$/, default => 'DESC' },
    });
    my $model = MottoIdea::Model::Idea::Rank->new;
    my $find_row = $model->find_recent_top(
        limit  => $params->{limit},
        offset => $params->{offset},
    );
    warn Data::Dumper::Dumper $find_row;
    my $results = $params->{order} eq 'DESC'
                  ? [ sort { $b->{tendency} <=> $a->{tendency} } @$find_row ]
                  : [ sort { $a->{tendency} <=> $b->{tendency} } @$find_row ];
    return $results;
    # my $sum = 0;
    # $sum += $_ for @params;
    # return $sum;
}

1;
