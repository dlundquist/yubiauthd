package YubiAuthd::AuthenticationSession;

use 5.010000;
use strict;
use warnings;

require Exporter;
use Carp;
require AnyEvent;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use YubiAuthd::AuthenticationSession':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.01';

sub new($$) {
    my ($class, $socket, $pid, $uid, $gid) = @_;

    my $self = {
        socket => $socket,
        pid => $pid,
        uid => $uid,
        gid => $gid,
    };

    bless $self, $class;

    $self->{w} = AnyEvent->io(
        fh         => $self->{socket},
        poll       => 'r',
        cb         => sub { $self->read_cb(); }
    );

    return $self;
}

sub read_cb($) {
    my ($self) = @_;

    my $msg = undef;
    $self->{socket}->recv($msg, 256, 0);

    if ($msg) {
        print "receive $msg from $self->{uid}\n";
    } else {
        $self->{socket}->shutdown(2);
        $self->{w} = undef;
    }
}

1;
