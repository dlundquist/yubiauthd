package YubiAuthd::SynchronizationSocket;

use 5.010000;
use strict;
use warnings;

require Exporter;
use Carp;
require IO::Socket::IP;
require Socket;
require AnyEvent;


our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use YubiAuthd::Identity ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.01';

sub new($$$) {
    my ($class,
        $ip,
        $port) = @_;

    my $socket = IO::Socket::IP->new(
        LocalHost    => $ip,
        LocalService => $port,
        Proto        => 'udp',
        Reuse        => 1,
        Blocking     => 0,
    ) or carp("$class->new(): invalid socket");

    my $self = {
        socket  => $socket,
        watcher => undef,
    };

    bless $self, $class;

    $self->{watcher} = AnyEvent->io(
        fh         => $self->{socket},
        poll       => 'r',
        cb         => sub { $self->_read_cb(); }
    );

    return $self;
}

sub _read_cb($) {
    my ($self) = @_;
    my $msg;
    my $peer_sa = $self->{socket}->recv($msg, 512, 0);
    my $peer_af = Socket::sockaddr_family($peer_sa);
    my $port = undef;
    my $ip = undef;
    if ($peer_af == Socket::AF_INET) {
        my ($ip4p, $ip4a) = Socket::unpack_sockaddr_in($peer_sa);
        $port = $ip4p;
        $ip = Socket::inet_ntop(Socket::AF_INET, $ip4a);
    } elsif ($peer_af == Socket::AF_INET6) {
        my ($ip6p, $ip6a, $scope_id, $flowinfo) = Socket::unpack_sockaddr_in6($peer_sa);
        $port = $ip6p;
        $ip = Socket::inet_ntop(Socket::AF_INET6, $ip6a);
    } else {
        carp("unexpected address family $peer_af");
    }

    print "SYNC PEER:\t$ip $port\n";
    print "SYNC DATA:\t$msg\n";
}

1;
