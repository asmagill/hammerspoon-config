#! /usr/bin/perl -wT

BEGIN { unshift (@INC, "/opt/amagill/perl/lib/perl5", "/opt/amagill/perl/lib/perl5/darwin-thread-multi-2level") ; }

use strict ;
use IPC::System::Simple qw(runx) ;

$ENV{'PERL5LIB'} = "/opt/amagill/perl/lib/perl5:/opt/amagill/perl/lib/perl5/darwin-thread-multi-2level" ;
$ENV{'PATH'} = "/opt/amagill/perl/bin:/usr/bin:/bin" ;

my ($buffer, @pairs, $pair, $name, $value, $k) ;
our (%FORM) ;

# Read in text
if ( !defined $ENV{'REQUEST_METHOD'} ) {
	$ENV{'REQUEST_METHOD'} = "GET" ;

	print "Type in the GET data for a web page (i.e. everything after the ? character.)\n" ;

	$ENV{'QUERY_STRING'} = <> ;
}

$ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/ ;

if ($ENV{'REQUEST_METHOD'} eq "POST") {
	read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'}) ;
} else {
	$buffer = $ENV{'QUERY_STRING'} ;
}

# Split information into name/value pairs

@pairs = split(/&/, $buffer) ;
foreach $pair (@pairs) {
	($name, $value) = split(/=/, $pair) ;
	$value =~ tr/+/ / ;
	$value =~ s/%(..)/pack("C", hex($1))/eg ;
	$FORM{$name} = $value ;
}

print "Content-type:text/html\r\n\r\n" ;
print "<html><head>\n" ;
print "<META HTTP-EQUIV=\"Pragma\" CONTENT=\"no-cache\">\n" ;
print "<META HTTP-EQUIV=\"Expires\" CONTENT=\"-1\">\n" ;
print "<title>Basic CGI-DUMP</title></head><body>\n" ;
print "<b>Basic CGI-DUMP</b>\n<hr>\n" ;

print "<table border=\"1\">\n" ;
print "<tr><th colspan=\"2\">Environment</th></tr>\n" ;
print "<tr><th>Key</th><th>Value</th>\n" ;
foreach $k (sort (keys %ENV)) { print "<tr><td>$k</td><td>$ENV{$k}</td></tr>\n" ; }
# print "</table>\n" ;

# print "<table>\n" ;
print "<tr><th colspan=\"2\">Form</th></tr>\n" ;
print "<tr><th>Key</th><th>Value</th>\n" ;
foreach $k (sort (keys %FORM)) { print "<tr><td>$k</td><td>$FORM{$k}</td></tr>\n" ; }
print "</table>\n" ;

print "</pre>\n" ;
print "<hr>\n<div align=\"right\"><i>" ; eval { runx("date") ; };
print "<h3>ERROR!</h3><hr>$@\n" if ($@) ;
print "</i></div>\n" ;
print  "</body></html>\n" ;

