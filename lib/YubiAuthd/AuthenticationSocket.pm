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
package YubiAuthd::AuthenticationSocket;

use 5.010000;
use strict;
use warnings;

require Exporter;
use IO::Socket::UNIX qw( SOCK_STREAM SOMAXCONN SO_PEERCRED );
use Carp;
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
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

sub new($%) {
    my ($class,
        %params) = @_;

    my $socket_path = $params{socket_path};
    my $identity_store = $params{identity_store};

    croak "$class->new(): invalid identity store" unless $identity_store->isa('YubiAuthd::IdentityStore');

    my $old_umask = umask(0000);

    unlink $socket_path if -S $socket_path;
    my $socket = IO::Socket::UNIX->new(
        Type        => SOCK_STREAM,
        Local       => $socket_path,
        Listen      => SOMAXCONN,
        Blocking    => 0,
    ) or croak "$class->new(): invalid socket";

    umask($old_umask);

    my $self = {
        identity_store  => $identity_store,
        socket_path     => $socket_path,
        socket          => $socket,
        watcher         => undef,
    };

    bless $self, $class;

    $self->{watcher} = AnyEvent->io(
        fh          => $self->{socket},
        poll        => 'r',
        cb          => sub { $self->_read_cb(); }
    );

    return $self;
}

sub identity_store($) {
    my ($self) = @_;

    return $self->{identity_store};
}


sub _read_cb($) {
    my ($self) = @_;

    my $sock = $self->{socket}->accept() or carp("read_cb: $!");

    # Grab the client credential info
    my $peercred = $sock->sockopt(SO_PEERCRED)
        or croak "Unable to fetch peer credentials: $!";
    my ($pid, $uid, $gid);
    my $os = $^O;

    if ($os eq 'linux') {
        # Unpack struct ucred
        ($pid, $uid, $gid) = unpack('lll', $peercred);
    } elsif ($os eq 'openbsd') {
        # Unpack struct sockpeercred
        ($uid, $gid, $pid) = unpack('lll', $peercred);
    } else {
        croak "Unsupported OS $os";
    }

    # Set client socket to nonblocking
    my $flags = $sock->fcntl(F_GETFL, 0);
    $sock->fcntl(F_SETFL, $flags | O_NONBLOCK);

    return YubiAuthd::AuthenticationSession->new($sock, $pid, $uid, $gid, $self);
}

1;
