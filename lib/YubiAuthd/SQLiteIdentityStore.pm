package YubiAuthd::SQLiteIdentityStore;

use 5.014002;
use strict;
use warnings;

require Exporter;
require YubiAuthd::IdentityStore;
require YubiAuthd::IdentityBuilder;
require YubiAuthd::Identity;
require DBI;
require DBD::SQLite;
use Carp;
use Data::Dumper;

our @ISA = qw(Exporter YubiAuthd::IdentityStore);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use YubiAuthd::SQLiteIdentityStore ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.01';

sub new {
    my $class = shift;

    my $self = $class->SUPER::new($class, @_);

    my $db_file = shift;

    $self->{db} = DBI->connect("dbi:SQLite:dbname=$db_file", {
            AutoCommit => 1,
            PrintError => 1
        })
        or croak "$class->new: unable to open SQLite DB $db_file";

    bless $self, $class;

    $self->_check_db();

    $self->subscribe($self);

    return $self;
}

sub load_by_public_id($$) {
    my ($self, $public_id) = @_;

    my $query = 'SELECT public_id, serial_number, username, aes_key, uid, counter FROM identities WHERE public_id=?';

    my $sth = $self->{db}->prepare($query);
    $sth->bind_param(1, $public_id, DBI::SQL_VARCHAR());
    $sth->execute()
        or croak "Unable to execute statement $query: " . $sth->errstr;
    my @row = $sth->fetchrow_array()
        or return undef; # no result;

    my $id_builder = YubiAuthd::IdentityBuilder->new($self);
    $id_builder->public_id($row[0]);
    $id_builder->serial_number($row[1]);
    $id_builder->username($row[2]);
    $id_builder->aes_key($row[3]);
    $id_builder->uid($row[4]);
    $id_builder->counter($row[5]);

    return $id_builder->build;
}

sub load_by_username($$) {
    my ($self, $username) = @_;

    my $query = 'SELECT public_id, serial_number, username, aes_key, uid, counter FROM identities WHERE username=?';

    my $sth = $self->{db}->prepare($query);
    $sth->bind_param(1, $username, DBI::SQL_VARCHAR());
    $sth->execute()
        or croak "Unable to execute statement $query: " . $sth->errstr;
    my @row = $sth->fetchrow_array()
        or return undef; # no result;

    my $id_builder = YubiAuthd::IdentityBuilder->new($self);
    $id_builder->public_id($row[0]);
    $id_builder->serial_number($row[1]);
    $id_builder->username($row[2]);
    $id_builder->aes_key($row[3]);
    $id_builder->uid($row[4]);
    $id_builder->counter($row[5]);

    return $id_builder->build;
}

sub store_identity($$) {
    my ($self, $identity) = @_;

    my $query = 'INSERT INTO identities (public_id, serial_number, username, aes_key, uid, counter) VALUES (?,?,?,?,?,?)';
    my $sth = $self->{db}->prepare($query);
    $sth->bind_param(1, $identity->public_id(), DBI::SQL_VARCHAR());
    $sth->bind_param(2, $identity->serial_number(), DBI::SQL_INTEGER());
    $sth->bind_param(3, $identity->username(), DBI::SQL_VARCHAR());
    $sth->bind_param(4, $identity->aes_key(), DBI::SQL_VARCHAR());
    $sth->bind_param(5, $identity->uid(), DBI::SQL_VARCHAR());
    $sth->bind_param(6, $identity->counter(), DBI::SQL_INTEGER());
    $sth->execute()
        or croak "Unable to execute statement $query: " . $sth->errstr;
}

sub notify($$) {
    my ($self, $identity) = @_;

    my $query = 'UPDATE identities SET counter=?, updated_at=CURRENT_TIMESTAMP WHERE public_id=? LIMIT 1';

    my $sth = $self->{db}->prepare($query);
    $sth->bind_param(1, $identity->counter(), DBI::SQL_INTEGER());
    $sth->bind_param(2, $identity->public_id(), DBI::SQL_VARCHAR());
    $sth->execute();

    croak("Error storing Identity's new counter value: $DBI::errstr\n") if ($self->{db}->err());

    return 1;
}

sub _check_db($) {
    my ($self) = @_;

    $self->{db}->do('CREATE TABLE IF NOT EXISTS identities (' .
                    'public_id TEXT UNIQUE NOT NULL,' .
                    'serial_number INTEGER,' .
                    'username TEXT UNIQUE NOT NULL,' .
                    'aes_key TEXT,' .
                    'uid TEXT,' .
                    'counter INTEGER NOT NULL DEFAULT 0,' .
                    'created_at INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP,' .
                    'updated_at INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP' .
                    ');');
    croak("Problem creating database: $DBI::errstr\n") if ($self->{db}->err());
}

1;
