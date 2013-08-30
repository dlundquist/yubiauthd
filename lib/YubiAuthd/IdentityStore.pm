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
package YubiAuthd::IdentityStore;

use 5.010000;
use strict;
use warnings;

require Exporter;
use Carp;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use YubiAuthd::IdentityStore ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';


# Preloaded methods go here.

sub new {
    my $class = shift;

    my $self = {
        subscribers => [],
    };

    bless $self, $class;

    return $self;
}

sub load_by_public_id {
    my $self = shift;
    my $class = ref $self;

    die "This method must be overridden by $class or another subclass of " . __PACKAGE__;
}

sub load_by_serial_number {
    my $self = shift;
    my $class = ref $self;

    die "This method must be overridden by $class or another subclass of " . __PACKAGE__;
}

sub load_by_username {
    my $self = shift;
    my $class = ref $self;

    die "This method must be overridden by $class or another subclass of " . __PACKAGE__;
}

sub subscribe($$) {
    my ($self, $subscriber) = @_;

    push(@{$self->{subscribers}}, $subscriber);
}

sub subscribers($) {
    my ($self) = @_;

    return $self->{subscribers};
}

1;
