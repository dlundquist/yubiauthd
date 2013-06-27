package YubiAuthd::Identity;

use 5.010000;
use strict;
use warnings;

require Exporter;
use Carp;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use YubiAuthd::Identity ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.01';

sub new($$$$$$$) {
    my ($class,
        $public_id,
        $serial_number,
        $username,
        $aes_key,
        $uid,
        $counter) = @_;

    carp("$class->new(): invalid public_id") unless $public_id =~ /\A[cbdefghijklnrtuv]{12}\Z/;
    carp("$class->new(): invalid username") unless $username =~ /\A[a-z_][a-z0-9_-]{0,30}\Z/;
    carp("$class->new(): invalid aes_key") unless length($aes_key) == 32;
    carp("$class->new(): invalid counter") unless $counter eq int($counter) + 0;

    my $self = {
        public_id       => $public_id,
        serial_number   => int($serial_number),
        username        => $username,
        aes_key         => $aes_key,
        uid             => $uid,
        counter         => int($counter),
    };

    bless $self, $class;

    return $self;
}

sub public_id($) {
    my $self = shift;

    return $self->{'public_id'};
}

sub serial_number($) {
    my $self = shift;

    return $self->{'serial_number'};
}

sub username($) {
    my $self = shift;

    return $self->{'username'};
}

sub aes_key($) {
    my $self = shift;

    return $self->{'aes_key'};
}

sub counter {
    my $self = shift;
    my $counter = shift;

    if (defined $counter) {
        croak(ref($self) . "->counter(): attempting to decrease counter") if (defined $self->{counter} && $counter < $self->{counter});
        $self->{counter} = $counter;
    }

    return $self->{'counter'};
}

1;
