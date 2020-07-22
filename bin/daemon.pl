#!/usr/bin/perl
use HTTP::Daemon;
use HTTP::Status;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use db;
use report;

use constant REPORT_SEARCH_LIMIT => 100;


my $d = HTTP::Daemon->new(
    LocalPort => 8080
) || die "Cannot run daemon: $!";


while (my $c = $d->accept) {
    while (my $req = $c->get_request) {
        if ($req->method eq 'GET'
            and $req->uri->path =~ "^/report"
        ){
            my %query = $req->url->query_form;

            my $html = getSearchForm($query{address});

            if ($query{address}) {
                $html .= getReport($query{address});
            }

            my $res = HTTP::Response->new(RC_OK);
            $res->content($html);
            $res->header('Content-Type' => 'text/html;charset=utf8');

            $c->send_response($res);
        }
        else {
            $c->send_error(RC_NOT_FOUND)
        }
    }
    $c->close;
    undef($c);
}

sub getSearchForm {
    my ($address) = @_;

    return qq{
    <form action="/report">
        Address: <input type="text" name="address" value="$address"><br>
        <input type="submit" value="Search">
    </form>
    };
}

sub getReport {
    my ($email) = @_;

    my $db     = db->new;
    my $report = report->new(
        dbh => $db->getDbh
    );

    my $html = '';

    my $found = $report->search($email, REPORT_SEARCH_LIMIT);
    if ($found) {
        if (@{ $found->{rows} }) {
            my $i = 1;
            $html .= sprintf("%03d: ", $i++) . "$_<br>\n" for @{ $found->{rows} };
            $html .= "More..." if $found->{more};
        }
        else {
            $html = "Not found";
        }
    }

    return $html;
}
