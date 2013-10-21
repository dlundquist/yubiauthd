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
package YubiAuthd::AuthenticationChallenge;

use 5.010000;
use strict;
use warnings;

require Exporter;
require Auth::Yubikey_Decrypter;
use Carp;
use constant {
    AUTH_CHALLENGE_LENGTH => 44,
};

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use YubiAuthd::AuthenticationChallenge ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.01';

sub new($$$) {
    my ($class, $challenge, $identity_store) = @_;

    croak "$class->new(): incomplete challenge" unless length($challenge) == AUTH_CHALLENGE_LENGTH;
    croak "$class->new(): invalid identity store" unless $identity_store->isa('YubiAuthd::IdentityStore');


    # Untaint our challenge string
    if ($challenge =~ m/^([cbdefghijklnrtuv]{44})$/) {
        $challenge = $1;
    } else {
        croak "$class->new(): invalid challenge modhex: $challenge";
    }

    my $self = {
        challenge       => $challenge,
        identity_store  => $identity_store,
    };

    bless $self, $class;

    return $self;
}

sub public_id($) {
    my ($self) = @_;

    return substr($self->{challenge}, 0, 12);
}

sub identity($) {
    my ($self) = @_;

    return $self->{identity_store}->load_by_public_id($self->public_id());
}

sub authenticate($) {
    my ($self) = @_;

    my $id = $self->identity
        or croak "Unknown identity";

    my ($ykpid, $yksid, $ykcounter, $yktimestamp, $yksession, $ykrand, $ykcrcdec, $ykcrcok) =
        Auth::Yubikey_Decrypter::yubikey_decrypt($self->{challenge}, $id->aes_key);

    croak "YubiKey CRC invalid" unless $ykcrcok;
    croak "YubiKey UID mismatch" unless $yksid eq $id->uid;

    my $old_counter = $id->counter;
    my $new_counter = $ykcounter * 1000 + $yksession;

    # Update the counter
    $id->counter($new_counter);

    # Do not authenticate unless the counter was incremented
    return undef unless $new_counter > $old_counter;

    # Authentication Challenge successful
    return $id;
}

1;
