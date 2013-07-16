package YubiAuthd::Identity;

use 5.010000;
use strict;
use warnings;

require Exporter;
require Scalar::Util;
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

sub new($%) {
    my ($class,
        %params) = @_;

    my $public_id       = $params{public_id};
    my $serial_number   = $params{serial_number};
    my $username        = $params{username};
    my $aes_key         = $params{aes_key};
    my $uid             = $params{uid};
    my $counter         = $params{counter};
    my $identity_store  = $params{identity_store};

    croak "$class->new(): invalid public_id" unless $public_id =~ /\A[cbdefghijklnrtuv]{12}\Z/;
    croak "$class->new(): invalid username" unless $username =~ /\A[a-z_][a-z0-9_-]{0,30}\Z/;
    croak "$class->new(): invalid aes_key" unless length($aes_key) == 32;
    croak "$class->new(): invalid counter" unless $counter eq int($counter) + 0;
    croak "$class->new(): invalid identity_store" unless $identity_store->isa('YubiAuthd::IdentityStore');

    my $self = {
        public_id       => $public_id,
        serial_number   => int($serial_number),
        username        => $username,
        aes_key         => $aes_key,
        uid             => $uid,
        counter         => int($counter),
        identity_store  => $identity_store,
    };

    # Prevent circular reference (id -> id_store -> subscribers includes id)
    Scalar::Util::weaken($self->{identity_store});

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
        my $incremented = $counter > $self->{counter} ? 1 : undef;
        croak(ref($self) . "->counter(): attempting to decrease counter") if $counter < $self->{counter};
        $self->{counter} = $counter;
        $self->_notify_subscribers() if $incremented;
    }

    return $self->{'counter'};
}

sub identity_store {
    my ($self) = $@;

    return $self->{identity_store};
}

sub subscribers {
    my ($self) = $@;

    return wantarray ?
           @{$self->identity_store()->subscribers()} :
           $self->identity_store()->subscribers();
}

sub _notify_subscribers($) {
    my ($self) = $@;

    foreach my $subscriber ($self->subscribers()) {
        $subscriber->notify($self);
    }
}

1;
