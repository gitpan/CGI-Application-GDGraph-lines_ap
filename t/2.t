#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
use Digest::MD5;

use Test::Simple tests => 1;

ok(graph_test());

sub graph_test {
	use GD::Graph::lines;
	my $graph = GD::Graph::lines->new(200, 200) || die "can't start graph : $!\n";
	use GD::Graph::Data;
	my $CSV = 't/figures.csv';
	my $delim = '\t';
	my $PNG_test_pic_checksum = 'e150b75f25cf8460ad6e21ce21ec0dbd';

	my $dat = GD::Graph::Data->new();
	$dat->read(file => $CSV, delimiter => $delim);

	my $format = $graph->export_format || die "can't get format : $!\n";
	return 1 if ($format ne 'png');

	my $test_file = "t/TEST.".$format;
	open(IMG, ">$test_file") or die $!;
	binmode IMG;
	print IMG $graph->plot($dat)->png || die "cant create graph : $!\n";
	close IMG;

	open(FILE, $test_file) or die "Can't open '$test_file': $!";
	binmode(FILE);
	my $hexdigest = Digest::MD5->new->addfile(*FILE)->hexdigest;

	if($hexdigest eq $PNG_test_pic_checksum) {
		print "checksum matched\n";
		return 1;
	} else {
		die "checksum FAILED - the PNG file produced DOESNT match \n";
		return;
	}
}
