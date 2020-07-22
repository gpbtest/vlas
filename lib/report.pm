package report;
use v5.010;
use strict;
use utf8;


sub new {
    my $class = shift;
    my %opts  = @_;

    return unless $opts{dbh};

    my $self = { %opts };
    bless $self, $class;

    return $self;
}

sub search {
    my $self = shift;
    my ($email, $limit) = @_;
    $limit ||= 10;

    my $sth = $self->{dbh}->prepare(qq{
        SELECT created, int_id, str
        FROM (
            -- log with address
            SELECT created, int_id, str
            FROM log
            WHERE address = ?

            UNION

            -- log without address
            SELECT log.created, log.int_id, log.str
            FROM log
                JOIN log addr ON addr.int_id = log.int_id
                    AND addr.address = ?
            WHERE log.address IS NULL

            UNION

            -- message without address
            SELECT m.created, m.int_id, m.str
            FROM message m
                JOIN log ON log.int_id = m.int_id
            WHERE log.address = ?
        ) t
        ORDER BY int_id, created
        LIMIT ?
    }) or die "Cannot prepare request: $!";

    $sth->execute(($email) x 3, $limit + 1);

    my @rows = ();

    while (my ($created, $int_id, $str) = $sth->fetchrow_array) {
        if ($limit--) {
            push @rows, join(" ", $created, $int_id, $str);
        }
    }

    return {
        rows => \@rows,
        more => ($limit < 0 ? 1 : 0)
    };
}

1;
