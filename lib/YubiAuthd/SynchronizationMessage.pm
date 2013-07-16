package YubiAuthd::SynchronizationMessage;

use 5.010000;
use strict;
use warnings;

require Exporter;
require Digest::HMAC_SHA1;
use Carp;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use YubiAuthd::SynchronizationMessage ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

            ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.01';

sub new($%) {
    my ($class, %params) = @_;

    if (defined $params{payload} and $params{key}) {
        my ($public_id, $counter, $digest) = unpack('A12 N A20', $params{payload});

        my $hmac = Digest::HMAC_SHA1->new($params{key});
        $hmac->add($public_id);
        $hmac->add($counter);

        croak "$class->new(): invalid HMAC" unless $hmac->digest eq $digest;

        $params{public_id} = $public_id;
        $params{counter} = $counter;
    }

    croak "$class->new(): invalid public_id" unless $params{public_id} =~ /\A[cbdefghijklnrtuv]{12}\Z/;
    croak "$class->new(): invalid counter" unless $params{counter} eq int($params{counter}) + 0;

    my $self = {
        public_id   => $params{public_id},
        counter     => $params{counter},
    };

    bless $self, $class;

    return $self;
}

sub public_id($) {
    my ($self) = @_;

    return $self->{public_id};
}

sub counter($) {
    my ($self) = @_;

    return $self->{counter};
}

sub payload($$) {
    my ($self, $key) = @_;

    my $hmac = Digest::HMAC_SHA1->new($key);

    $hmac->add($self->{public_id});
    $hmac->add($self->{counter});

    return pack('A12 N A20', $self->public_id, $self->counter, $hmac->digest);
}

1;
