#!/usr/bin/perl -T

use Test::More tests => 16;

use warnings;
use strict;
use File::Basename;
use lib dirname(__FILE__) . '/../lib';
use File::Temp;
use IO::Socket::IP;
use Socket;
use DBI;
use Carp;
use AnyEvent;
use YubiAuthd::Identity;
use YubiAuthd::SQLiteIdentityStore;
use YubiAuthd::SynchronizationSocket;
use YubiAuthd::SynchronizationPeer;

my $shared_key = '7P3ycZeLdgGNkh4B89u2TC1J';

#
# Start up a yubiauthd server without an authentication socket
#
sub start_sync_server {
    my ($sync_port, $db_path, $peer_port) = @_;

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

        my $sync_socket = YubiAuthd::SynchronizationSocket->new(
                ip_address      => '127.0.0.1',
                port            => $sync_port,
                peers           => [ YubiAuthd::SynchronizationPeer->new(
                    ip_address  => '127.0.0.1',
                    port        => $peer_port,
                    shared_key  => $shared_key
                    )],
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

    return $pid;
}

sub send_sync_message {
    my ($port, $counter, %params) = @_;
    my $source_ip   = $params{source_ip} || '127.0.0.1';
    my $key         = $params{shared_key} || $shared_key;

    my $sync_message = YubiAuthd::SynchronizationMessage->new(
            public_id => 'vvvvvvvvvvvv',
            counter => $counter
            );

    my $sock = IO::Socket::IP->new(
            PeerHost    => '127.0.0.1',
            PeerPort    => $port,
            LocalHost   => $source_ip,
            Proto       => 'udp'
            ) or croak("unable to open UDP socket:  $!");

    $sock->send($sync_message->payload($key))
        or croak("unable to send UDP synchronization message: $!");

    $sock->shutdown(2);
    $sock->close();
}

sub external_ip {
    my $sock = IO::Socket::IP->new(
            PeerHost => '192.0.2.10',
            PeerPort => 1024,
            Proto    => 'udp'
            ) or croak("unable to open UDP socket:  $!");

    my ($port, $ipaddr) = Socket::sockaddr_in($sock->sockname());
    my $ip = Socket::inet_ntop(Socket::AF_INET, $ipaddr);
    $sock->close();

    return $ip;
}

my $test_servers = [
    {
        name        => 'first',
        db_path     => tmpnam() . '.sqlite',
        sync_port   => 8715,
        peer_port   => 8447,
        pid         => undef
    },
    {
        name        => 'second',
        db_path     => tmpnam() . '.sqlite',
        sync_port   => 8447,
        peer_port   => 8715,
        pid         => undef
    }
];

sub assert_counter_value {
    my ($expected_counter, $test_msg) = @_;

    foreach my $server (@{$test_servers}) {
        my $db = DBI->connect("dbi:SQLite:dbname=" . $server->{db_path})
            or die $!;

        my $query = 'SELECT counter FROM identities WHERE public_id=?';
        my $sth = $db->prepare($query);
        $sth->bind_param(1, 'vvvvvvvvvvvv', DBI::SQL_VARCHAR());
        $sth->execute();

        my @row = $sth->fetchrow_array()
            or die "Identity not present";

        is($row[0], $expected_counter, $server->{name} . " server " . $test_msg);
    }
}

# Start our test servers
foreach my $server (@{$test_servers}) {
    $server->{pid} = start_sync_server(
            $server->{sync_port},
            $server->{db_path},
            $server->{peer_port});
}

# Wait for server to start
sleep 1;
assert_counter_value(0, "should start at zero");
send_sync_message($test_servers->[0]->{sync_port}, 500);
sleep 1;
assert_counter_value(500, "should increment when first server is updated");
send_sync_message($test_servers->[1]->{sync_port}, 600);
sleep 1;
assert_counter_value(600, "should increment when second server is updated");
send_sync_message($test_servers->[0]->{sync_port}, 300);
sleep 1;
assert_counter_value(600, "should not decrease");
send_sync_message($test_servers->[0]->{sync_port}, 700, source_ip => external_ip());
sleep 1;
assert_counter_value(600, "should not accept updates from unknown peers");
send_sync_message($test_servers->[0]->{sync_port}, 800, shared_key => 'xxxxxxxxxxxxxxxxxxxx');
sleep 1;
assert_counter_value(600, "should not accept updates with different shared keys");
send_sync_message($test_servers->[0]->{sync_port}, 900);
sleep 1;
assert_counter_value(900, "should still accept valid updates after receiving junk");


foreach my $server (@{$test_servers}) {
    kill 'TERM', $server->{pid};
    waitpid($server->{pid}, 0);
    unlink($server->{db_path});
    is($?, 0, $server->{name} . " server should exit successfully");
}
