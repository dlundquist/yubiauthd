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
package YubiAuthd::Log;

use 5.010000;
use strict;
use warnings;

require Exporter;
require Sys::Syslog;
require POSIX;
use Carp;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use YubiAuthd::Log ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    closelog openlog syslog
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( closelog openlog syslog );

our $VERSION = '0.01';

my $syslog_active = undef;

sub closelog {
    if ($syslog_active) {
        $syslog_active = undef;
        return Sys::Syslog->closelog;
    }
}

sub openlog {
    $syslog_active = 1;
    return Sys::Syslog->openlog(@_);
}

sub syslog {
    if ($syslog_active) {
        return Sys::Syslog->syslog(@_);
    } else {
        my $priority = shift @_;
        my $msg = shift @_;
        $msg = sprintf($msg, @_) if @_;

        my $timestamp = POSIX::strftime("%b %e %H:%M:%S", gmtime);
        print STDERR "$timestamp $msg\n";
    }
}

1;
