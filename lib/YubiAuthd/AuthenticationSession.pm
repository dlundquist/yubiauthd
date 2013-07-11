package YubiAuthd::AuthenticationSession;

use 5.010000;
use strict;
use warnings;

require Exporter;
use Carp;
use Data::Dumper;
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
        socket  => $socket,
        pid     => $pid,
        uid     => $uid,
        gid     => $gid,
        watcher => undef,
    };

    bless $self, $class;

    $self->{watcher} = AnyEvent->io(
        fh         => $self->{socket},
        poll       => 'r',
        cb         => sub { $self->_read_cb(); },
    );

    return $self;
}

sub _read_cb($) {
    my ($self) = @_;

    my $msg = undef;
    $self->{socket}->recv($msg, 256, 0);

    if ($msg) {
        print "message from " . Dumper($self) . ":\n$msg";
        $self->{socket}->send("DENIED\n");
    } else {
        $self->{socket}->shutdown(2);
        $self->{watcher} = undef;
    }
}

1;
