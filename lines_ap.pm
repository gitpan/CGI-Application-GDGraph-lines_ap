package CGI::Application::GDGraph::lines_ap;

# See the bottom of this file for the POD documentation.  Search for the
# string '=head'.

# You can run this file through either pod2man or pod2html to produce pretty
# documentation in manual or html file format (these utilities are part of the
# Perl 5 distribution).
#
# Copyright (C) 2004 jonbrookes@bigfoot.com
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.  I request that this copyright
# notice remain attached to the file.  You may modify this module as you 
# wish, but if you redistribute a modified version, please attach a note
# listing the modifications you have made.

# The most recent version and complete docs are available at:
#   http://www.jonblog.net

use 5.006001;
use strict;
use warnings;
use Carp 'croak';

our $VERSION = '0.01';

use base qw(CGI::Session);
use CGI::Application;
use GD::Graph::Data;
use GD::Graph::lines;
use Data::Dumper;

our @ISA = qw(CGI::Application);

sub setup {
  my $self = shift;
  $self->mode_param("rm");
  $self->start_mode("graph_html");
  $self->run_modes(graph_img => "graph_img",
                   graph_html => "graph_html",
	   );
}

sub graph_img {
  	my $self        = shift;
  	my $cgi         = $self->query();
	my $legend      = $self->param('legend');
	my $x           = $self->param('x_size');
	my $y           = $self->param('y_size');
	my $session_dir = $self->param('session_dir');
	#
	#########
	# establish existing or create 
	# new session object and pass 
	# cookie to browser
	#########
	my $session = new CGI::Session(undef, $cgi, {Directory=>$session_dir});
	$session -> expire('+1h');
	#########
	# retrieve parameters saved
	# to the session or read
	# newly passed ones from CGI
	#########
	my $TITLE = $cgi->param('name') || $session->param('name');
	my $x_label   = $self->param('x_label')   || undef;
	my $y_label   = $self->param('y_label')   || undef;
	my $fgclr     = $self->param('fgclr')     || undef;
	my $labelclr  = $self->param('labelclr')  || undef;
	my $legendclr = $self->param('legendclr') || undef;
	my $text_clr  = $self->param('textclr')   || undef;


	my $cookie = $cgi->cookie(
		-name    =>'CGISESSID',
		-value   => $session->id,
		-expires =>'+1h',
	);


	#########
	# define graph object 
	#########
	my $graph = GD::Graph::lines->new($x, $y);
	my $data = $session->param('GRAPH_DAT');
	my ($max_y_val, $skip_x_val,$vals) = $self->iterate_data_for_params($data, $x);
	my $vals_label = "vals[$vals]";
	
	#########
	# configure graph parameters
	#########
	$graph->set(
		x_label           => $x_label,
		x_label_skip      => $skip_x_val,
		y_label           => $y_label,
		title             => $TITLE,
		y_max_value       => $max_y_val,
		x_labels_vertical => 1,
		long_ticks        => 1,
		fgclr             => $fgclr,
		labelclr          => $labelclr,
		legendclr         => $legendclr,
	) or croak $graph->error;

	$graph->set_legend(@$legend);
	$graph->set_text_clr($text_clr);

	#########
	# output header c/w cookie 
	# and graph image 
	#########
	# switch off CGI::Application headers
	$self->header_type('none');
	my $format = $graph->export_format;
	# print our own header
	print $cgi->header(
		-cookie => $cookie,
		-type   => "image/$format"
	);
	binmode STDOUT;
	print $graph->plot($data)->$format();

	#########
	# save session data
	#########
	$session->save_param($cgi);

	########
	# cheat CGI::Application 
	# rule to never 'print' to STDOUT
	########
	return '';

}

# x_label_ratio
#  - sets or gets value x_label_ratio
#  - used to divide the pixel size of x dimention
#    to get a number of x values to display on
#    the axis
sub x_label_ratio {
	my ($self, $x_label_ratio) = @_;
	$self->{'x_label_ratio'} = $x_label_ratio if ($x_label_ratio);
	return $x_label_ratio;
}
	
# iterate_data_for_params
# - taken a reference to the data structure to be plotted
#   and the x dimention in pixels, 
#   iterate the data structure, missing out the values used for the x
#   axes as 'key' values
#   work out the largest value for feeding to y axis 
#   and calculate the optimal amount of x values according to
#   x_label_ratio (see it's accessor) and the pixel size of 
#   the graph
sub iterate_data_for_params {
	my $self = shift;
	my $data = shift;
	my $x_dim = shift;
	my $vals = @{$data->[0]};
	my $x;
	my $max = 0;
	foreach $x (1..@{$data}) {
        	my $col = $data->[$x];
		my $row = 0;
        	foreach $row (@{$col}) {
                	if($row) { if($row > $max) { $max = $row } }
        	}
	}
	my $x_label_ratio = $self->{'x_label_ratio'} || 20;
	my $skip_x_val = ($vals/$x_label_ratio)-1;
	return ($max, $skip_x_val, $vals);
}

sub graph_html {
	my $self        = shift;
  	my $dat         = $self->param('DAT');
	my $session_dir = $self->param('session_dir');
	my $cgi         = $self->query();   
	#########
	# establish existing or create
	# new session object and pass
	# cookie to browser
	#########
	$self->header_type('none');
	my $session = new CGI::Session(undef, $cgi, {Directory=>$session_dir});
	$session -> expire('+1h');
	my $cookie = $cgi->cookie(
			-name    =>'CGISESSID',
			-value   => $session->id,
			-expires =>'+1h',
	);

	# print our own header
	my $output = undef;
	$output =  $cgi->header(
				-cookie => $cookie,
	);

	#########
	# save session data
	#########
	$session->param( "GRAPH_DAT", $dat);
	$session->save_param($cgi);

	#########
	# output html
	#########
	return $output = $self->_html(out=>$output);
}

sub _html {
	my ($self, @params) = @_;
	my %params = @params;
	my $cgi = $self->query();   
	my $output = $params{out};
	my $tmpl = $self->param('tmpl');
	my $tmpl_obj = $self->load_tmpl($tmpl);

	my $this_script= $cgi->url(-relative=>1).'?rm=graph_img';
	$tmpl_obj ->param(page_title=> $self->param('page_title'));
	$tmpl_obj ->param(graph_img => $this_script);
	$output .= $tmpl_obj->output;
	$output .= $cgi->end_html;
	return $output;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CGI::Application::GDGraph::lines_ap - Perl extension for CGI::Application, using GDGraph and CGI::Session

=head1 SYNOPSIS


 my $session_file_directory = '/<path>/<to>/<session>/<file>/directory>';
 # NB: session_file_directory must be writable by user under which the web server runs

 # instantiate the graph application object and run it
 #

 my $graph = CGI::Application::GDGraph::lines_ap->new(
	TMPL_PATH => $path_to_templates,
	PARAMS    => {
		'DAT'        => $dat,
		'legend'     => \@legend,
		'x_size'     => 600,
		'y_size'     => 300,
		'x_label'    => 'X LABEL HERE',
		'y_label'    => 'Y LABEL HERE',
		'page_title' => 'GRAPH TITLE HERE',
		'tmpl'       => $html_template,
		'session_dir'=> $session_file_directory,
		'fgclr'      => '#222222',
		'labelclr'   => '#777777',
		'legendclr'  => '#666666',
		'textclr'    => '#666666',
	}
 );


 $graph->x_label_ratio("25");
 $graph->run();
  
where :

	TMPL_PATH => $path_to_templates,

is the directory location of the HTML template (see EXAMPLES)

		'DAT'        => $dat,

is a reference to a data structure (see EXAMPLES for an expanation of it's composition)

		'legend'     => \@legend,

is a reference to a list containing the name of each data series in the order that they appear in the 'DAT' structure

		'x_size'     => 600,
		'y_size'     => 300,

specifies the size of the graph to be generated along it's X and Y axis in pixels respectively

		'x_label'    => 'X LABEL HERE',
		'y_label'    => 'Y LABEL HERE',

gives the graph label names for the X and Y axis respectively

		'page_title' => 'GRAPH TITLE HERE',

is the tile of the graph page and is rendered in HTML

		'tmpl'       => $html_template,

file name of the 'template' file to render HTML (see EXAMPLES for further details)

		'session'    => $session_file_dir,

where the session data is to be held - this must be WRITABLE by the user that your web server 
runs under (/tmp on UNIX systems would be an example of a directory like this)

		'fgclr'      => '#222222',
		'labelclr'   => '#777777',
		'legendclr'  => '#666666',
		'textclr'    => '#666666',

are the colors defined each by hex values for each of the graph's textual and line items

 $graph->x_label_ratio("25");

is and optional parameter specifying the maximum amount of values to be shown in the 'X' access

=head1 DESCRIPTION

This module is written with a view to its use in the area of performance and availablity management of small to large computer
systems where data such as CPU, disk, swap usage are more easily interpreted when plotted as graphical images. This need 
not be the only application of this module as any numeric 'tabular' data may be plotted using this method.

Although it is easy to generate graphs 'on the fly' using GD and the Perl module GD::Graph, 
having a re-usable module that can be customised and rapidly deployed throughout a web 
infrastucture can cut out a lot of 'cutting and pasting'. 

The combination of CGI::Application, CGI::Session and GD::Graph into this 'wrapper' 
module seeks to make this task easier and quicker.

An on line graph together with an HTML page in which to render it that is itself 'template driven' should be easy to
set up within the framework that this module has to offer. Session state data is maintained by CGI::Session so there is 
little need to transfer complex 'CGI parameter based' data between the outer web application and this module. Thus
data transfer is simplified and potentialy more secure.

=head1 EXAMPLES

The following examples use the following preamble which instantiates a new instance of this module.

Each example uses an HTML template file as defined in 'EXAMPLE TEMPLATE' (below)

 #!/usr/bin/perl -w
 use strict; 
 use CGI::Application::GDGraph::lines_ap;
 use GD::Graph::Data;
 # if we want to query a database 
 use DBI;

 my $path_to_templates      = '/<path>/<to>/<templates>/<dir>';
 my $html_template          = '<template filename>';
 my $session_file_directory = '/<path>/<to>/<session>/<file>/directory>';
 # NB: session_file_directory must be writable by user under which the web server runs

 # obtain a reference to a data structure that holds the data
 # to be graphed
 my $dat = &get_raw_data;

 # populate a list with names for each data set or column (this could also be the product of an SQL query)
 my @legend = qw(CPU Swap Load_Avg);

 my $graph = CGI::Application::GDGraph::lines_ap->new(
       TMPL_PATH => $path_to_templates,
       PARAMS    => {
               'DAT'        => $dat,
               'legend'     => \@legend,
               'x_size'     => 600,
               'y_size'     => 300,
               'x_label'    => 'X LABEL HERE',
               'y_label'    => 'Y LABEL HERE',
               'page_title' => 'GRAPH TITLE HERE',
               'tmpl'       => $html_template,
               'session_dir'=> $session_file_directory,
               'fgclr'      => '#222222',
               'labelclr'   => '#777777',
               'legendclr'  => '#666666',
               'textclr'    => '#666666',
       }
 );

 $graph->x_label_ratio("25");
 $graph->run();

The line 'use GD::Graph::Data' is only used when GD::Graph::Data is used to populate the data structure for passing to the 'lines' graph object

How you arrive at a data structure that is referenced to by the '$dat' reference is the subject of the following sub headings, each
of which provide a different version of the function '&get_raw_data'

=head2 CGI::Session Data session based data

 # get_raw_data
 # accepts no parameters and returns a reference to a data structure
 sub get_raw_data {
 	my $session = new CGI::Session(
                                undef,
				$cgi,
				{Directory=>$session_file_directory}
	);
 	$session -> expire('+1h');
 	return $session->param('GRAPH_DATA');
 }

 .....

and then somewhere else under another script or application

 # some function or other that generates data and stores into suitable data structure
 #
 $session->param( "GRAPH_DAT", \@dat);

where the appropriate measures have been taken to start up a CGI::Session - see CGI::Session's docs for this

=head2 mySQL query based graph usinig GD::Graph::Data

 # get_raw_data
 # accepts no parameters and returns a reference to a data structure
 sub get_raw_data {
	my (%attr) =
		(
			PrintError => 0,
			RaiseError => 0
		);

	# instantiate a new Data object with a reference called '$dat'
	my $dat = GD::Graph::Data->new();

	# connect to our database
	my $dbh = DBI->connect(
                "DBI:mysql:<mysqldatabase_name>:<hostname_of_mysql_server>"
                . ";mysql_read_default_file=/etc/my.cnf",
                '<username>',
                '<password>',
                \%attr
                ) or die "Unable for connect to server";

	# set up the sql query
	my $sql = "select datetime, cpu, swap, load_avg
	           from my_data 
		   order by datetime desc
	           limit 288;
        # prepare and run the query
	my @row = ();
	my $sth = $dbh->prepare($sql) || die "sql failed";
	$sth->execute;

	# collect the results and save into the data structure
        while (@row = $sth->fetchrow_array) {
             $dat->add_point(@row);
        }
	return \@dat;
 }

=head2 mySQL query based graph

The following is an example of how an SQL query could be used to insert data into a data structure for use in a graph object.

The data structure is built from scratch, not using GD::Graph::Data methods and the data is added a 'column' or 'data set'
at a time. In the case of this example, this suits the nature of the data that is being queried. A table of data that contains
a single column of figures together with an 'id' and 'datetime' column is queried in a for loop.

 # get_raw_data
 # accepts no parameters and returns a reference to a data structure
 sub get_raw_data {
	my (%attr) =
		(
			PrintError => 0,
			RaiseError => 0
		);

	my $dbh = DBI->connect(
                "DBI:mysql:<mysqldatabase_name>:<hostname_of_mysql_server>"
                . ";mysql_read_default_file=/etc/my.cnf",
                '<username>',
                '<password>',
                \%attr
                ) or die "Unable for connect to server";

	# a list of 'ids' that could themselves be the product of a parameter passed to this script
	# or another SQL query
	my @ids = qw (26133 26135 26133);
	my $col = 0;
	my @dat = ();
	# iterate the list of 'ids' and insert a column of figures at a time into the data structure
	foreach my $id (@ids) {
		my $sql = "select datetime, stat 
		           from my_data where id = $id 
			   order by datetime desc
		           limit 288;
		my @row = ();
		my $sth = $dbh->prepare($sql) || die "sql failed";
		$sth->execute;
		my $row=0;
		$col++;
		while (@row = $sth->fetchrow_array) {
			my ($datetime, $stat) = @row;
			$dat[0][$row] = $datetime;
			$dat[$col][$row] = $stat;
			$row++;
		}
	}
	return \@dat;
 }

=head2 CSV flat text file data generated graph

 sub get_raw_data {
	my $CSV = '/<path>/<to>/<csv>/<data file>';
	my $delim = ",";
        my $dat = GD::Graph::Data->new();
        $dat->read(file => $CSV, delimiter => $delim);
 }

 The CSV data refered to by '$CSV' must contain a string with the path to a filename that contains 
 comma separated data in a structure as outlined in 'SAMPLE CSV DATA' (below)

=head3 SAMPLE CSV DATA

 # This is a comment, and will be ignored
 Jan,12,24,40
 Feb,13,37,34
 # March is missing
 Mar		
 Apr,9,18,23
 May,40,20,99
 Jun,50,40,23.8

=head2 SAMPLE TEMPLATE

 <head>
 <title><TMPL_VAR NAME="page_title"></title>
 </head>
 <body>
 
 <table border=1>
 <tr>
 <td align="center"><H1><TMPL_VAR NAME="page_title"></H1></td>
 </tr>
 <tr>
 <td><img src = "/cgi-bin/<TMPL_VAR NAME="graph_img">"></td>
 </tr>
 </table>
 </body>

=head1 INTERNAL SUBROUTINES

The following documents the internal methods or subroutines of the CGI::Appliciation::GDGraph::lines_ap object. For the most part
it is expected for this section to be ignored by users of the module. However, if you wish to 'extend' the functionality of 
this module by creating a class of your own that 'inherits' from this module, this may be of more interest.

=over 

=item setup

the method that 'starts up' a CGI::Application and dictates the number of 'run modes' and the 'default start mode'
which is here defined as 'graph_html' - which produces the HTML in which a graph will be called using an 'img' tag.
Run mode is defined by the CGI parameter 'rm' which can only be 'graph_img' or 'graph_html' in this applicaton.

changing or overriding this subroutine would alter the way the whole module behaves. It is likely that you don't want to do this
and starting your own CGI::Applicatoin may be a better option

The follwoing run modes are defined:

=over

=item * graph_img

in this run mode, it is expected that the application will produce binary graphics data together with a corresponding mime type. 
Its output is to SDTOUT (straight to the browser)

=item * graph_html

this is the DEFAULT run mode and this will output HMTL using a template file that has been provided. The template file MUST have
an appropriate '<IMG=""> tag pointing back to this module - see EXAMPLES for 'TEMPLATE'

=back

=item graph_img

accepts the following required cgi parameters:

=over 

=item * legend

a reference to a list of values that represent the names of each consecutive data set in the graph

=item * x_size

an integer that is used to set the X size of the graph image

=item * y_size

an integer that is used to set the Y size of the graph image

=back

this method does not return any values. It is normal for CGI::Application run-time methods to return their 'output' 
which is sent by CGI::Application to STDOUT. 'Printing' to STDOUT within in CGI::Application method is not supported
but in this case HAS been done in order that the image file may be sent straight to STDOUT by the method and not 
itself having to be buffered by the module.

This method therefore 'returns' an empty string post to it 'printing' to STDOUT itself.

=item graph_html

accepts the following required CGI parameters:

=over

=item * $dat

a reference to the data structure (a list of lists or the data structue returned by GD::Graph::Data). This is stored into the session object
which then serializes this data and writes it to disk for this session

=item * $session_dir

the directory file location that session data is stored

=back 

graph_html returns a single scalar '$output' which is html for CGI::application to send to STDOUT for rendering by the client browser.

a call to the internal method _html is intended that this part of the html page can be extended by a.n.other module that inherits from 
this one without having to paste the whole graph_html method into the new one. This was an idea in development and therefore 
may be removed in later releases.

=back

=head1 SEE ALSO

GD - must be installed and running on the system and available as binaries

http://www.boutell.com/gd/

Perl Modules that this is a part of or uses:

=over

=item * CGI::Application - this 'is a' CGI::Application

=item * CGI::Session - to manage session data

=item * GD::Graph::Data - to import data to GD::Graph

=item * GD::Graph::lines_ap - the GD Perl Graphing module itself

=back 

there is no mailing list as to yet for this module (CGI::Application::GDGraph::lines_ap) but there is a wiki for CGI::Application under which this module runs as an application:

http://twiki.med.yale.edu/twiki2/bin/view/CGIapp/WebHome

http://www.jonblog.net - hosts a wiki and blog that has details of this module (CGI::Application::GDGraph::lines_ap) and other things

=head1 AUTHOR

Jon Brookes, E<lt>jonbrookes@bigfoot.com<gt>

thanks and gratis to : 

Birmingham PM, Barbie for help, patches and suggestions

=head1 BUGS

likely, this is pre-beta ALPHA release and has only been tested on 2 different platforms and 3 systems.

one of he 'test scripts' is known to give errors on some systems where a checksum is returned from the PNG file that is
created that differs from that of the origonal system.

any bug reports to the author please : jonbrooke@bigfoot.com

=head1 TODO

=over

=item * significant testing and the addition of more meaningful test scripts

=item * improved API to support more / all current parameters as offered by GD::Graph

=item * incorporation of other graph 'types' - for example Pie, Mixed, Bar

=item * inclusion of both CGI and method parameter validation

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by jonbrookes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

