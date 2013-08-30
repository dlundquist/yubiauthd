use Test::More tests => 5;

BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . '/../../lib';
    use_ok( 'YubiAuthd::SynchronizationMessage' );
}

my $test_shared_key = 'SecretKey';
my $test_public_id  = 'bfjnhgdhgrub';
my $test_counter    = 42;


my $tx_sm = YubiAuthd::SynchronizationMessage->new(
        public_id => $test_public_id,
        counter   => $test_counter
        );

is($tx_sm->public_id, $test_public_id, 'Stored public_id');
is($tx_sm->counter, $test_counter, 'Stored counter');

my $payload = $tx_sm->payload($test_shared_key);

my $rx_sm = YubiAuthd::SynchronizationMessage->new(
        payload => $payload,
        key => $test_shared_key
        );

is($rx_sm->public_id, $test_public_id, 'Received public_id');
is($rx_sm->counter, $test_counter, 'Received counter');


