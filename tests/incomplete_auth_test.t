#!/usr/bin/perl -T

use Test::More tests => 1;

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

    my $sock = IO::Socket::UNIX->new($auth_sock_path)
        or die $!;

    $sock->print($otp);

    return $sock->getline() eq "AUTHENTICATION SUCCESSFUL\n";

    $sock->close();
}

#
# Start up a yubiauthd server without any synchronization peers
#
my $server_pid = fork();
unless (defined $server_pid) {
    die "fork: $!";
} elsif ($server_pid == 0) {
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

my $client_pid = fork();
unless (defined $client_pid) {
    die "fork: $!";
} elsif ($client_pid == 0) {
    my $sock = IO::Socket::UNIX->new($auth_sock_path)
        or die $!;

    $sock->print("too short");

    # This causes the socket to terminate abnormally and
    # replicates the select invalid file descriptor error
    kill 9, $$;

    sleep 1;

    $sock->close();

    exit(0);
}

# Wait for child to complete
waitpid($client_pid, 0);

is ( try_auth('vvvvvvvvvvvvgvndkrfkgclkktfftnnckctrhjdcdkid'), 1, "Auth request after partial request");


kill $server_pid;

# Clean up test files
unlink $db_path;
unlink $auth_sock_path;
