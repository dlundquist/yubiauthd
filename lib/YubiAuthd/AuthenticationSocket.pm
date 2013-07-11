package YubiAuthd::AuthenticationSocket;

use 5.010000;
use strict;
use warnings;

require Exporter;
use IO::Socket::UNIX qw( SOCK_STREAM SOMAXCONN SO_PEERCRED );
use Carp;
require YubiAuthd::AuthenticationSession;
require AnyEvent;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use YubiAuthd::AuthenticationSocket ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.01';

sub new($$) {
    my ($class,
        $socket_path) = @_;

    unlink $socket_path if -S $socket_path;
    my $socket = IO::Socket::UNIX->new(
        Type       => SOCK_STREAM,
        Local      => $socket_path,
        Listen     => SOMAXCONN,
        Blocking   => 0,
    ) or carp("$class->new(): invalid socket");

    my $self = {
        socket => $socket,
        socket_path => $socket_path,
    };

    bless $self, $class;

    $self->{w} = AnyEvent->io(
        fh         => $self->{socket},
        poll       => 'r',
        cb         => sub { $self->read_cb(); }
    );

    return $self;
}

sub read_cb($) {
    my ($self) = @_;

    my $sock = $self->{socket}->accept() or carp("read_cb: $!");
    my ($pid, $uid, $gid) = unpack('lll', $sock->sockopt(SO_PEERCRED));
    print "accept connection form $sock\n";

    return YubiAuthd::AuthenticationSession->new($sock, $pid, $uid, $gid);
}

1;
