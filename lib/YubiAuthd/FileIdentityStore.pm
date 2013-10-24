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
package YubiAuthd::FileIdentityStore;

use 5.010000;
use strict;
use warnings;

require Exporter;
require YubiAuthd::IdentityStore;
require YubiAuthd::IdentityBuilder;
require YubiAuthd::Identity;
use Carp;
use Data::Dumper;

our @ISA = qw(Exporter YubiAuthd::IdentityStore);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use YubiAuthd::FileIdentityStore ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.01';


sub new {
    my $class = shift;

    my $self = $class->SUPER::new($class, @_);

    my $store_dir = shift;

    carp("$class->new(): invalid store_dir") unless -d $store_dir &&
                                                       "$store_dir/keynums" &&
                                                       "$store_dir/keys" &&
                                                       "$store_dir/state" &&
                                                       "$store_dir/users";

    $self->{store_dir} = $store_dir;

    bless $self, $class;

    $self->subscribe($self);

    return $self;
}

sub load_by_public_id($$) {
    my ($self, $public_id) = @_;

    my $id_builder = YubiAuthd::IdentityBuilder->new($self);
    my $serial_number = undef;

    # First lookup the serial number with a full directory scan
    opendir(SERIAL_DIR, $self->{store_dir} . '/keynums')
        or croak(ref($self) . "->load_by_public_id($public_id) failed to open keynums directory");
    while (my $filename = readdir(SERIAL_DIR)) {
        my $filepath = $self->{store_dir} . '/keynums/' . $filename;

        next unless -f $filepath and -r $filepath;

        open(SERIAL_FILE, $filepath)
            or croak(ref($self) . "->load_by_public_id($public_id) failed to open $filepath");

        if (<SERIAL_FILE> =~ m/^$public_id$/) {
            $serial_number = $filename;
            $id_builder->serial_number($serial_number);
            $id_builder->public_id($public_id);
        }

        close(SERIAL_FILE);
    }
    closedir(SERIAL_DIR);

    unless ($serial_number) {
        carp "Unable to find public_id " . $public_id;
        return undef;
    }


    # Lookup the username with another full directory scan
    opendir(USERNAME_DIR, $self->{store_dir} . '/users')
        or croak(ref($self) . "->load_by_public_id($public_id) failed to open username directory");
    while (my $username = readdir(USERNAME_DIR)) {
        my $filepath = $self->{store_dir} . '/users/' . $username;

        next unless -l $filepath and -r $filepath;

        if (readlink($filepath) =~ m/\/keynums\/$serial_number$/) {
            $id_builder->username($username);
        }
    }
    closedir(USERNAME_DIR);

    my $key_file = "$self->{store_dir}/keys/$public_id";

    open(KEY_FH, $key_file)
        or croak(ref($self) . "->load_by_public_id($public_id) failed to open $key_file");
    my $uid = <KEY_FH>;
    chomp($uid);
    $uid =~ s/\s+//g;
    $id_builder->uid($uid);
    my $aes_key = <KEY_FH>;
    chomp($aes_key);
    $aes_key =~ s/\s+//g;
    $id_builder->aes_key($aes_key);
    close(KEY_FH);

    my $state_file = "$self->{store_dir}/state/$public_id";
    if (open(STATE_FH, $state_file)) {
        my $counter = int(<STATE_FH>);
        $id_builder->counter($counter);
        close(STATE_FH);
    } else {
        $id_builder->counter(0);
    }

    return $id_builder->build;
}

sub load_by_username($$) {
    my ($self, $username) = @_;

    my $username_link = "$self->{store_dir}/users/$username";

    # Reject trivial case
    return undef unless -l $username_link;

    my $id_builder = YubiAuthd::IdentityBuilder->new($self);
    $id_builder->username($username);

    if (readlink($username_link) =~ m/\/keynums\/(\d+)$/) {
        $id_builder->serial_number(int($1));
    }

    open(PUBLIC_ID_FH, $username_link)
        or die("open: $!");
    my $public_id = <PUBLIC_ID_FH>;
    chomp($public_id);
    close(PUBLIC_ID_FH);
    $id_builder->public_id($public_id);

    my $key_file = "$self->{store_dir}/keys/$public_id";

    open(KEY_FH, $key_file)
        or die("open: $!");
    my $uid = <KEY_FH>;
    chomp($uid);
    $uid =~ s/\s+//g;
    $id_builder->uid($uid);
    my $aes_key = <KEY_FH>;
    chomp($aes_key);
    $aes_key =~ s/\s+//g;
    $id_builder->aes_key($aes_key);
    close(KEY_FH);

    my $state_file = "$self->{store_dir}/state/$public_id";
    if (open(STATE_FH, $state_file)) {
        my $counter = int(<STATE_FH>);
        $id_builder->counter($counter);
        close(STATE_FH);
    } else {
        $id_builder->counter(0);
    }

    return $id_builder->build;
}

sub notify($$) {
    my ($self, $identity) = @_;
    my $state_file = $self->{store_dir} . '/state/' . $identity->public_id;

    open(STATE, '>', $state_file)
        or croak(ref($self) . "->notify() failed to open $state_file");
    print STATE $identity->counter;
    close(STATE)
        or croak(ref($self) . "->notify() failed to close $state_file");
}

1;
