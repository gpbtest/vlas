package db;
use v5.010;
use strict;
use utf8;

use DBI;


sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub getDbh {
    my $self = shift;

    $self->{dbh} ||= $self->_getDbh(
        pg    => 'gpb',
        name  => 'gpb_test',
        host  => '127.0.0.1',
        user  => 'gpb_test',
        pwd   => '123'
    );

    return $self->{dbh};
}

sub clearTable {
    my $self = shift;
    my ($table) = @_;

    $self->{dbh}->do(
        "TRUNCATE $table"
    )
    or die "Cannot truncate $table: $!";
}

sub _getDbh {
    my $self = shift;
    my ($db_type, $token, %opts) = @_;
    $token ||= 'local';

    state $dbh = {};

    if (not exists $dbh->{ $token }) {
        $dbh->{ $token } = DBI->connect(
            $self->_getDSN($db_type, %opts),
            $opts{user},
            $opts{pwd},
            {}
        )
        or die "Cannot connect to db: $!";
    }

    return $dbh->{ $token };
}

sub _getDSN {
    my $self = shift;
    my ($db_type, %opts) = @_;

    if ($db_type eq 'pg') {
        return sprintf("dbi:Pg:dbname=%s;host=%s;port=%d",
            $opts{name}, $opts{host}, $opts{port} || 5432);
    }
    elsif ($db_type eq 'mysql') {
        return sprintf("dbi:mysql:database=%s;host=%s;port=%d",
            $opts{name}, $opts{host}, $opts{port} || 3306);
    }

    return undef;
}

1;
