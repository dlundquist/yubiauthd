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
package YubiAuthd::AuthenticationSession;

use 5.010000;
use strict;
use warnings;

require Exporter;
use Carp;
require AnyEvent;
require YubiAuthd::AuthenticationChallenge;
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

sub socket_identity($) {
    my ($self) = @_;

    return $self->identity_store()->load_by_username($self->username());
}

sub remaining_challenge_bytes($) {
    my ($self) = @_;

    return AUTH_CHALLENGE_LENGTH - length($self->{input_buffer});
}

sub challenge_identity($) {
    my ($self) = @_;

    return undef if $self->remaining_challenge_bytes();

    my $identity = undef;
    eval {
        my $challenge = YubiAuthd::AuthenticationChallenge->new($self->{input_buffer}, $self->identity_store());
        $identity = $challenge->authenticate();
    };
    if ($@) {
        carp $@;
        return undef;
    }

    return $identity;
}

sub _read_cb($) {
    my ($self) = @_;
    my $msg = undef;

    $self->{client_socket}->recv($msg, $self->remaining_challenge_bytes(), 0);
    return $self->shutdown() unless ($msg); # Client closed connection

    $self->{input_buffer} .= $msg;

    return if ($self->remaining_challenge_bytes() > 0); # Incomplete request

    my $challenge_id = $self->challenge_identity()
        or return $self->shutdown("Unable to find challenge identity");

    my $socket_id = $self->socket_identity()
        or return $self->shutdown("Unable to find socket identity");

    return $self->shutdown("Socket and challenge identities do no match") unless $challenge_id->public_id eq $socket_id->public_id;

    $self->{client_socket}->send("AUTHENTICATION SUCCESSFUL\n");
    $self->{client_socket}->shutdown(2);
    $self->{watcher} = undef;
}

sub shutdown($$) {
    my ($self, $reason) = @_;

    $self->{client_socket}->send("DENIED\n");
    $self->{client_socket}->shutdown(2);
    $self->{watcher} = undef;
    carp $reason;

    return undef;
}

1;
