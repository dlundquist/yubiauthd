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
package YubiAuthd::IdentityBuilder;

use 5.010000;
use strict;
use warnings;

require Exporter;
use Carp;
require YubiAuthd::Identity;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use YubiAuthd::IdentityBuilder ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.01';

sub new($$) {
    my ($class, $store) = @_;

    croak "$class->new(): invalid identity store" unless $store->isa('YubiAuthd::IdentityStore');

    my $self = {
        public_id       => undef,
        serial_number   => undef,
        username        => undef,
        aes_key         => undef,
        uid             => undef,
        counter         => undef,
        identity_store  => $store,
    };

    bless $self, $class;
    return $self;
}

sub build($) {
    my $self = shift;

    return YubiAuthd::Identity->new(
        public_id       => $self->{public_id},
        serial_number   => $self->{serial_number},
        username        => $self->{username},
        aes_key         => $self->{aes_key},
        uid             => $self->{uid},
        counter         => $self->{counter},
        identity_store  => $self->{identity_store}
    );
}

sub public_id($$) {
    my ($self, $public_id) = @_;

    $self->{public_id} = $public_id;

    return $self;
}

sub serial_number($$) {
    my ($self, $serial_number) = @_;

    $self->{serial_number} = $serial_number;

    return $self;
}

sub username($$) {
    my ($self, $username) = @_;

    $self->{username} = $username;

    return $self;
}

sub aes_key($$) {
    my ($self, $aes_key) = @_;

    $self->{aes_key} = $aes_key;

    return $self;
}

sub uid($$) {
    my ($self, $uid) = @_;

    $self->{uid} = $uid;

    return $self;
}

sub counter($$) {
    my ($self, $counter) = @_;

    $self->{counter} = $counter;

    return $self;
}

1;
