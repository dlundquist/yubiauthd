package YubiAuthd::IdentityStore;

use 5.014002;
use strict;
use warnings;

require Exporter;

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
    die "This method must be overridden by a subclass of __PACKAGE__";
}

sub find_by_public_id {
    die "This method must be overridden by a subclass of __PACKAGE__";
}

sub find_by_serial_number {
    die "This method must be overridden by a subclass of __PACKAGE__";
}

1;
