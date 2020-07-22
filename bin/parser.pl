#!/usr/bin/perl
use v5.010;
use strict;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use db;


my $db = db->new;
my $dbh = $db->getDbh;
$db->clearTable($_) for qw(message log);

LOGROW:
while (my $log_row = <>) {
    my ($date, $time, $int_id, $tail) = split /\s/, $log_row, 4;
    my $created = $date . ' ' . $time;
    chomp $tail;

    state $sem_re = join '|', map { qr/\Q$_\E/ } qw(<= => -> ** ==);

    my ($sem, $address) = $tail =~ /^($sem_re)\s(\S+)\s/;

    if ($sem eq '<=') {
        my ($id) = $tail =~ /id=(\S+)/;

        unless ($id) {
            # warn "Invalid message id: $log_row";
            # next LOGROW;

            state $invalid_id = 1;
            $id = "INVALID_ID_" . $invalid_id++;
        }

        addMessage($dbh,
            created => $created,
            id      => $id,
            int_id  => $int_id,
            str     => $tail
        );
    }
    else {
        addLog($dbh,
            created => $created,
            int_id  => $int_id,
            str     => $tail,
            address => $address
        );
    }
}

sub addMessage {
    my ($dbh, %opts) = @_;

    $dbh->do(
        "INSERT INTO message (created, id, int_id, str) VALUES (?,?,?,?)",
        undef,
        map { $opts{ $_ } } qw(created id int_id str),
    )
    or die "Cannot insert message: $!";
}

sub addLog {
    my ($dbh, %opts) = @_;

    $dbh->do(
        "INSERT INTO log (created, int_id, str, address) VALUES (?,?,?,?)",
        undef,
        map { $opts{ $_ } } qw(created int_id str address),
    )
    or die "Cannot insert log: $!";
}

