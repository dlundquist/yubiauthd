#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';

use YubiAuthd::FileIdentityStore;
use Data::Dumper;

my $store = YubiAuthd::FileIdentityStore->new("./yubiauth");

print Dumper $store;

my $user = $store->load_by_username('dlundquist');

print Dumper $user;


use EV;
use AnyEvent;
use YubiAuthd::AuthenticationSocket;

my $auth_socket = YubiAuthd::AuthenticationSocket->new("/tmp/yubiauth.sock");

# Run our event loop
AnyEvent->condvar->recv;
