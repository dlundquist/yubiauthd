package YubiAuthd::FileIdentityStore;

use 5.014002;
use strict;
use warnings;

require Exporter;
require YubiAuthd::IdentityStore;
require YubiAuthd::IdentityBuilder;
use Carp;

our @ISA = qw(Exporter YubiAuthd::IdentityStore);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use YubiAuthd::FileIdentityStore ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';


sub new {
    my $class = shift;
    my $store_dir = shift;

    carp("$class->new(): invalid store_dir") unless -d $store_dir &&
                                                       "$store_dir/keynums" &&
                                                       "$store_dir/keys" &&
                                                       "$store_dir/state" &&
                                                       "$store_dir/users";

    my $self = {
        store_dir => $store_dir
    };

    bless $self, $class;

    return $self;
}

sub load_by_username($$) {
    my ($self, $username) = @_;

    my $username_link = "$self->{store_dir}/users/$username";

    # Reject trivial case
    return undef unless -l $username_link;

    my $id_builder = YubiAuthd::IdentityBuilder->new();
    $id_builder->username($username);

    if (readlink($username_link) =~ m/\/keynums\/(\d+)$/) {
        $id_builder->serial_number(int($1));
    }

    open(PUBLIC_ID_FH, $username_link)
        or die("open: $!");
    my $public_id = <PUBLIC_ID_FH>;
    chomp($public_id);
    close(PUBLIC_ID_FH);
    $id_builder->public_id($public_id);

    my $key_file = "$self->{store_dir}/keys/$public_id";

    open(KEY_FH, $key_file)
        or die("open: $!");
    my $uid = <KEY_FH>;
    chomp($uid);
    $uid =~ s/\s+//g;
    $id_builder->uid($uid);
    my $aes_key = <KEY_FH>;
    chomp($aes_key);
    $aes_key =~ s/\s+//g;
    $id_builder->aes_key($aes_key);
    close(KEY_FH);

    my $state_file = "$self->{store_dir}/state/$public_id";
    open(STATE_FH, $state_file)
        or die("open: $!");
    my $counter = int(<STATE_FH>);
    $id_builder->counter($counter);
    close(STATE_FH);

    return $id_builder->build;
}

1;