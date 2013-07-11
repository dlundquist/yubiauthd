package YubiAuthd::IdentityBuilder;

use 5.010000;
use strict;
use warnings;

require Exporter;
require YubiAuthd::Identity;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use YubiAuthd::Identity ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.01';

sub new() {
    my ($class) = @_;

    my $self = {
        public_id       => undef,
        serial_number   => undef,
        username        => undef,
        aes_key         => undef,
        uid             => undef,
        counter         => undef,
        subscribers     => undef,
    };

    bless $self, $class;
    return $self;
}

sub build($) {
    my $self = shift;

    return YubiAuthd::Identity->new(
        $self->{public_id},
        $self->{serial_number},
        $self->{username},
        $self->{aes_key},
        $self->{uid},
        $self->{counter},
        $self->{subscribers}
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

sub subscribers($$) {
    my ($self, $subscribers) = @_;

    $self->{subscribers} = $subscribers;

    return $self;
}

1;
