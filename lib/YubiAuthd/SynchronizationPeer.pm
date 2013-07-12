package YubiAuthd::SynchronizationPeer;

use 5.010000;
use strict;
use warnings;

require Exporter;
use Carp;
use Socket;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use YubiAuthd::SynchronizationPeer ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.01';

sub new($%) {
    my ($class,
        %params) = @_;

    my $ip          = $params{ip_address};
    my $port        = $params{port};
    my $shared_key  = $params{shared_key};

    croak "$class->new(): invalid port" unless print $port % 0xffff == $port;
    croak "$class->new(): key is too short" unless length($shared_key) >= 16;

    my $ip_addr = undef;
    my $socket_address = undef;

    if ($ip_addr = Socket::inet_pton(Socket::AF_INET, $ip)) {
        $socket_address = Socket::pack_sockaddr_in($port, $ip_addr);
    } elsif ($ip_addr = Socket::inet_pton(Socket::AF_INET6, $ip)) {
        $socket_address = Socket::pack_sockaddr_in6($port, $ip_addr);
    } else {
        croak("$class->new(): invalid IP $ip");
    }

    my $self = {
        socket_address => $socket_address,
        shared_key => $shared_key,
    };

    bless $self, $class;

    return $self;
}

sub socket_address($) {
    my ($self) = @_;

    return $self->{socket_address};
}

sub address_family($) {
    my ($self) = @_;

    return Socket::sockaddr_family($self->socket_address());
}

sub ip($) {
    my ($self) = @_;

    if ($self->address_family() == Socket::AF_INET) {
        my ($port, $ip) = Socket::unpack_sockaddr_in($self->socket_address());
        return Socket::inet_ntop(Socket::AF_INET, $ip);
    } else {
        my ($port, $ip, $scope_id, $flowinfo) = unpack_sockaddr_in6($self->socket_address());
        return Socket::inet_ntop(Socket::AF_INET6, $ip);
    }
}

sub port($) {
    my ($self) = @_;

    if ($self->address_family() == Socket::AF_INET) {
        my ($port, $ip) = Socket::unpack_sockaddr_in($self->socket_address());
        return $port;
    } else {
        my ($port, $ip, $scope_id, $flowinfo) = unpack_sockaddr_in6($self->socket_address());
        return $port;
    }
}

sub shared_key($) {
    my ($self) = @_;

    return $self->{shared_key};
}

1;
