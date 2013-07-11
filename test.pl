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
use YubiAuthd::SynchronizationSocket;

my $auth_socket = YubiAuthd::AuthenticationSocket->new("/tmp/yubiauth.sock");
my $sync_socket = YubiAuthd::SynchronizationSocket->new('::', 16000);

# Run our event loop
AnyEvent->condvar->recv;
