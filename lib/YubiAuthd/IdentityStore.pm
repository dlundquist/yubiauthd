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
    my $class = shift;
    die "This method must be overridden by $class or another subclass of " . __PACKAGE__;
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
    my ($self, $subscriber) = $@;

    $self->{subscribers} ||= [];
    push(@{$self->{subscribers}}, $subscriber);
}

sub subscribers($) {
    my ($self) = $@;

    return $self->{subscribers};
}

1;
