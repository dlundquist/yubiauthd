use Test::More tests => 1;

BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . '/../../lib';
    use_ok( 'YubiAuthd::IdentityBuilder' );
}

