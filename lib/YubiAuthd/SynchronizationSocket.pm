#
# Copyright 2013 Blue Box Group, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
package YubiAuthd::SynchronizationSocket;

use 5.010000;
use strict;
use warnings;

require Exporter;
require IO::Socket::IP;
require Socket;
require AnyEvent;
require YubiAuthd::IdentityStore;
require YubiAuthd::SynchronizationMessage;
use Carp;


our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use YubiAuthd::SynchronizationSocket ':all';
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
    my $id_store    = $params{identity_store};
    my $peers       = $params{peers} || [];

    croak "$class->new(): invalid port" unless $port % 0xffff == $port;
    croak "$class->new(): invalid identity store" unless $id_store->isa('YubiAuthd::IdentityStore');
    croak "$class->new(): invalid peers" unless ref($peers) eq 'ARRAY';
    if (my @bad_peers = grep(!$_->isa('YubiAuthd::SynchronizationPeer'), @{$peers})) {
        croak "$class->new(): invalid peers: @bad_peers";
    }

    my $socket = IO::Socket::IP->new(
        LocalHost       => $ip,
        LocalService    => $port,
        Proto           => 'udp',
        Reuse           => 1,
        Blocking        => 0,
    ) or croak("$class->new(): invalid socket");

    my $self = {
        socket                  => $socket,
        identity_store          => $id_store,
        synchronization_peers   => $peers,
        watcher                 => undef,
    };

    bless $self, $class;

    # Subscribe each peer to the identity store
    foreach my $peer (@{$self->{synchronization_peers}}) {
        $id_store->subscribe($peer);
    }

    $self->{watcher} = AnyEvent->io(
        fh      => $self->{socket},
        poll    => 'r',
        cb      => sub { $self->_read_cb(); }
    );

    return $self;
}

sub _lookup_peer($$) {
    my ($self, $ip) = @_;

    foreach my $peer (@{$self->{synchronization_peers}}) {
        return $peer if ($peer->ip eq $ip);
    }

    carp "Unkown peer $ip";

    return undef;
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
        return;
    }

    eval {
        my $peer = $self->_lookup_peer($ip);
        return unless $peer;

        my $sync_msg = YubiAuthd::SynchronizationMessage->new(
                payload => $msg,
                key     => $peer->shared_key
                );

        my $id = $self->{identity_store}->load_by_public_id($sync_msg->public_id);
        return unless $id;

        $id->counter($sync_msg->counter);
    };
    carp $@ if ($@);
}

1;
