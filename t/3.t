#!/usr/bin/perl -w
use strict;
use warnings;
use CGI;
use base qw(CGI::Session);
use Data::Dumper;
use Digest::MD5;

use Test::Simple tests => 1;

my $dump = 't/session_dump.txt';

ok(session_test());

sub session_test {
	my @dat = qw (1 2 3 4 5 6 7 8 9 10);
	my $cgi = new CGI;
	my $session =  new CGI::Session(undef, $cgi, {Directory=>"t/"});
	$session -> expire('+1h');

	# save session data
	$session->param( "GRAPH_DAT", \@dat);
	$session->save_param($cgi);
	$session->dump($dump);
	if(session_data_has_dat($dump)) {
		return 1;
	}
}

sub session_data_has_dat {
	my $dump = shift;
	open(T, "$dump") || die "can't open $dump : $!\n";
	my $b = undef;
	while(<T>) {
        	$b .= $_;
	}
	$b =~ m/(GRAPH_DAT.+?\])/s;

	my $m = $1;
	$m =~ s/\n//g;
	$m =~ s/\t| //g;

	my $match = q(GRAPH_DAT'=>['1','2','3','4','5','6','7','8','9','10']);

	if($m ne $match) {
        	die "session data does not match\n";
	} else {
		1;
	}
}


