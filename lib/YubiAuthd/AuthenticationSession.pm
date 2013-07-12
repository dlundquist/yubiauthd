package YubiAuthd::AuthenticationSession;

use 5.010000;
use strict;
use warnings;

require Exporter;
use Carp;
use Data::Dumper;
require AnyEvent;
use constant {
    AUTH_CHALLENGE_LENGTH => 44,
};

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use YubiAuthd::AuthenticationSession ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.01';

sub new($$) {
    my ($class, $client_socket, $pid, $uid, $gid, $authentication_socket) = @_;

    my $self = {
        client_socket           => $client_socket,
        pid                     => $pid,
        uid                     => $uid,
        gid                     => $gid,
        watcher                 => undef,
        authentication_socket   => $authentication_socket,
        input_buffer            => "",
    };

    bless $self, $class;

    $self->{watcher} = AnyEvent->io(
        fh         => $self->{client_socket},
        poll       => 'r',
        cb         => sub { $self->_read_cb(); },
    );

    return $self;
}

sub username($) {
    my ($self) = @_;

    return getpwuid($self->{uid});
}

sub authentication_socket($) {
    my ($self) = @_;

    return $self->{authentication_socket};
}

sub identity_store($) {
    my ($self) = @_;

    return $self->authentication_socket()->identity_store();
}

sub identity($) {
    my ($self) = @_;

    return $self->identity_store()->load_by_username($self->username());
}

sub remaining_challenge_bytes($) {
    my ($self) = @_;

    return AUTH_CHALLENGE_LENGTH - length($self->{input_buffer});
}

sub _read_cb($) {
    my ($self) = @_;

    my $msg = undef;
    $self->{client_socket}->recv($msg, $self->remaining_challenge_bytes(), 0);

    unless ($msg) {
        carp ref($self) . "->_read_cb(): client closed connection";
        $self->{client_socket}->shutdown(2);
        $self->{watcher} = undef;
        return;
    }

    $self->{input_buffer} .= $msg;

    return if ($self->remaining_challenge_bytes() > 0); # Incomplete request

    #my $challenge = YubiAuthd::AuthenticationChallenge->new($self->{input_buffer}, $self->identity_store());

    print "received auth challenge: $self->{input_buffer}\n";
    $self->{input_buffer} = "";

    $self->{client_socket}->send("DENIED\n");
    $self->{client_socket}->shutdown(2);
    $self->{watcher} = undef;
}

1;
