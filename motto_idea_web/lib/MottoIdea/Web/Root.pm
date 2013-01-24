package MottoIdea::Web::Root;
use Mojo::Base 'Mojolicious::Controller';
use FormValidator::Lite;
use HTML::FillInForm::Lite;
use Data::GUID::URLSafe;
use Text::VimColor;
use Encode;

sub index {
    my $self = shift;
    $self->render();
}

sub post {
     my $self = shift;
     my $validator = FormValidator::Lite->new($self->req);

     # エラーメッセージを設定
     $validator->set_message(
        'title.not_null' => 'Title is Empty',
        'body.not_null' => 'Body is Empty',
    );
    # 入力値チェック
    my $res = $validator->check(
        title => [qw/NOT_NULL/],
        body => [qw/NOT_NULL/],
    );
    # もし入力値が正しくなかったら
    if ($validator->has_error) {
        my @messages = $validator->get_error_messages;
        $self->stash->{error_messages} = \@messages;
        # 入力された値を充填しながら、描画
        my $html = $self->render_partial('root/index')->to_string;
        return $self->render_text(
            HTML::FillInForm::Lite->fill(\$html, $self->req->params),
            format => 'html',
        );
    }

    # 入力値の妥当性が保証された

    my $entry = $self->app->db->insert('entry',{
        id => Data::GUID->new->as_base64_urlsafe,
        title => $self->req->param('title'),
        body => $self->req->param('body'),
    });

    $self->redirect_to('/paste/' . $entry->id );

}

sub entry {
    my $self = shift;
    my $entry = $self->app->db->single('entry',{ id => $self->stash->{id} });
    unless( $entry ){
        return $self->render_not_found;
    }
    my $syntax = Text::VimColor->new(
        filetype => 'perl',
        string   => encode_utf8( $entry->body )
    );
    $self->stash->{code} = decode_utf8($syntax->html);
    $self->stash->{entry} = $entry;
}


1;
