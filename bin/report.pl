#!/usr/bin/perl
use v5.010;
use strict;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use db;
use report;


my $db     = db->new;
my $report = report->new(
    dbh => $db->getDbh
);

my $found = $report->search('iuh@mtw.ru', 10);
if ($found) {
    if (@{ $found->{rows} }) {
        say $_ for @{ $found->{rows} };
        say "More..." if $found->{more};
    }
    else {
        say "Not found"
    }
}

