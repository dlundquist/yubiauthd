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
    if ($challenge =~ m/^[cbdefghijklnrtuv]{AUTH_CHALLENGE_LENGTH}$/) {
        $challenge = $1;
    } else {
        croak "$class->new(): invalid challenge modhex"
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

    return substr $self->{challenge}, 0, 12;
}

sub identity($) {
    my ($self) = @_;

    return $self->{identity_store}->load_by_public_id($self->public_id());
}

sub authenticate($) {
    my ($self) = @_;

    my $newstate = auth_otp($code,$privateid,$aeskey,$laststate);
    authfail() unless ($newstate);

}

1;
