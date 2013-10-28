#!/usr/bin/perl -T

use Test::More tests => 10;

use warnings;
use strict;
use File::Basename;
use lib dirname(__FILE__) . '/../lib';
use File::Temp;
use IO::Socket::UNIX qw( SOCK_STREAM );
use Data::Dumper;

use AnyEvent;
use YubiAuthd::Identity;
use YubiAuthd::SQLiteIdentityStore;
use YubiAuthd::AuthenticationSocket;

# One Time Passwords for this test YubiKey:
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
    my $result = '';

    my $old_sigalrm = $SIG{ALRM};
    eval {
        local $SIG{ALRM} = sub { die "try_auth() Timed Out" };
        alarm 3;

        my $sock = IO::Socket::UNIX->new($auth_sock_path)
            or die $!;

        $sock->print($otp);

        $result = $sock->getline() eq "AUTHENTICATION SUCCESSFUL\n";

        alarm 0;
    };
    print STDERR $@ if $@;
    $SIG{ALRM} = $old_sigalrm;

    return $result;
}

#
# A poorly behaved yubiauth client
#
sub incomplete_auth($) {
    my $otp = shift;

    my $client_pid = fork();
    unless (defined $client_pid) {
        die "fork: $!";
    } elsif ($client_pid == 0) {
        my $sock = IO::Socket::UNIX->new($auth_sock_path)
            or die $!;

        $sock->print($otp);

        # This causes the socket to terminate abnormally and
        # replicates the select invalid file descriptor error
        kill(9, $$);

        sleep 1;

        # Should not be reached
        $sock->close();
        exit(0);
    }
    # Wait for client to complete
    my $result = waitpid($client_pid, 0);

    # Return true if the client was terminated by SIGKILL
    return ($result == $client_pid) && (($? & 127) == 9);
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

    my $done = AnyEvent->condvar;

    my $w = AnyEvent->signal(
        signal => "TERM",
        cb     => sub { $done->send }
    );

    # Run our event loop
    $done->recv;
    exit(0);
}

# Wait for server to start
sleep 2;

is( try_auth('vvvvvvvvvvvvgvndkrfkgclkktfftnnckctrhjdcdkid'), 1, "First use of OTP");
is( try_auth('vvvvvvvvvvvvgvndkrfkgclkktfftnnckctrhjdcdkid'), '', "Second use of same OTP");
is( try_auth('vvvvvvvvvvvvfrejuvtrhdgjbfdvirhnrhfdnnujdkfv'), 1, "First use of another OTP");
is( try_auth('vvvvvvvvvvvvgvndkrfkgclkktfftnnckctrhjdcdkid'), '', "Reuse of older OTP");
is( try_auth('iivkctnggrtiulkrvgdtnbgjnkfthbcgugvfccrflkug'), '', "Using another identities OTP");
is( try_auth('too_short'), '', "Too short of a OTP");
is( try_auth('vvvvvvvvvvvvlfftgeblljetvrbfgtvgfcklcgidjtdb'), 1, "First use of a third OTP");
is( incomplete_auth('too_short'), 1, "Incomplete authentication session");
is( try_auth('vvvvvvvvvvvvbhkhklvucncruneeilrbvvuilbthdrth'), 1, "First use of a fourth OTP");


kill 'TERM', $pid;
waitpid($pid, 0);

is($?, 0, "Server exited successfully");

# Clean up test files
unlink $db_path;
unlink $auth_sock_path;

