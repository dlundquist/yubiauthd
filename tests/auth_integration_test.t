#!/usr/bin/perl -T

use Test::More tests => 8;

use File::Basename;
use lib dirname(__FILE__) . '/../lib';
use File::Temp;
use IO::Socket::UNIX qw( SOCK_STREAM );
use Data::Dumper;

use AnyEvent;
use YubiAuthd::Identity;
use YubiAuthd::SQLiteIdentityStore;
use YubiAuthd::AuthenticationSocket;

# Open Time Passwords for this test YubiKey:
#
#    vvvvvvvvvvvvgvndkrfkgclkktfftnnckctrhjdcdkid
#    vvvvvvvvvvvvfrejuvtrhdgjbfdvirhnrhfdnnujdkfv
#    vvvvvvvvvvvvlfftgeblljetvrbfgtvgfcklcgidjtdb
#    vvvvvvvvvvvvbhkhklvucncruneeilrbvvuilbthdrth
#    vvvvvvvvvvvvnlhrddtkfihecunhrvcbifbrunlbcbev
#    vvvvvvvvvvvvvetjunjudeuevtcdnrcrkluinjgdggji
#    vvvvvvvvvvvvuubrlgjkihehdtglvrfiuvcgjehffukr
#    vvvvvvvvvvvvevlkturcnljbtjhcihgtitvubdutiueg
#    vvvvvvvvvvvvecedhlicgrgvvlvctknfuibrfhcgkehj
#    vvvvvvvvvvvvtkjfkvjfcnhbtvkttvtkjduvjjcbdcrn

my $db_path = tmpnam() . '.sqlite';
my $auth_sock_path = tmpnam() . '.sock';

#
# Simple yubiauth client
#
sub try_auth($) {
    my $otp = shift;

    my $sock = IO::Socket::UNIX->new($auth_sock_path)
        or die $!;

    $sock->print($otp);

    return $sock->getline() eq "AUTHENTICATION SUCCESSFUL\n";
}

#
# Start up a yubiauthd server without any synchronization peers
#
my $pid = fork();
unless (defined $pid) {
    die "fork: $!";
} elsif ($pid == 0) {
    my $store = YubiAuthd::SQLiteIdentityStore->new($db_path);

    my $id = YubiAuthd::Identity->new(
        public_id       => 'vvvvvvvvvvvv',
        serial_number   => 1466182,
        username        => scalar(getpwuid($<)),
        aes_key         => '00000000000000000000000000000000',
        uid             => 'ffffffffffff',
        counter         => 0,
        identity_store  => $store
    );

    $store->store_identity($id);

    my $auth_socket = YubiAuthd::AuthenticationSocket->new(
        socket_path     => $auth_sock_path,
        identity_store  => $store
    );

    # Run our event loop
    AnyEvent->condvar->recv;
    exit(0);
}

# Wait for server to start
sleep 2;

is( try_auth('vvvvvvvvvvvvgvndkrfkgclkktfftnnckctrhjdcdkid'), 1, "First use of OTP");
is( try_auth('vvvvvvvvvvvvgvndkrfkgclkktfftnnckctrhjdcdkid'), '', "Second use of OTP");
is( try_auth('vvvvvvvvvvvvfrejuvtrhdgjbfdvirhnrhfdnnujdkfv'), 1, "First use of another OTP");
is( try_auth('vvvvvvvvvvvvgvndkrfkgclkktfftnnckctrhjdcdkid'), '', "Reuse of older OTP");
is( try_auth('iivkctnggrtiulkrvgdtnbgjnkfthbcgugvfccrflkug'), '', "Using another identities OTP");
is( try_auth('too_short'), '', "Too short of a OTP");
is( try_auth('vvvvvvvvvvvvlfftgeblljetvrbfgtvgfcklcgidjtdb'), 1, "First use of another OTP");


kill $pid;

is($?, 0, "Server exited successfully");

# Clean up test files
unlink $db_path;
unlink $auth_sock_path;

