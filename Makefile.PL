use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Application::GDGraph::lines_ap',
    VERSION_FROM      => 'lines_ap.pm', # finds $VERSION
    PREREQ_PM         => {
    				GD               => undef, 
				CGI::Application => undef,
				GD::Graph	 => undef,
				GD::Graph::Data	 => undef,
				HTML::Template   => undef,
				CGI::Session     => undef,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lines_ap.pm', # retrieve abstract from module
       AUTHOR         => 'jon brookes <jonbrookes@bigfoot.com>') : ()),
);
