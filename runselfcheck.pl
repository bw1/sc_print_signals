#!/usr/bin/perl
#
#  run self check
#
use strict;
use YAML qw/DumpFile LoadFile/;
use File::Slurper qw/read_text write_text/;
use File::Path qw/make_path rmtree/;
use Cwd;

my $wd= getcwd(); 
my $wp= "tmp";
my $configp= "irssi_config";
my $debug=0;
my @scripts;
my $scrf= LoadFile('tests.yaml');

my $startup= <<'END';
^set ignore_signals int quit term alrm usr1 usr2
^set use_status_window off
^set autocreate_windows off
^set -clear autocreate_query_level
^set autoclose_windows off
^set reuse_unused_windows on
^set log_timestamp %H:%M:%S
run "$W/selfcheckhelperscript.pl"
END

#save
#^load perl
#^script exec $$^W = 1
# ^set settings_autosave off
# ^set -clear log_close_string
# ^set -clear log_day_changed
# ^set -clear log_open_string
# ^set log_timestamp * 
print `irssi --version`;
print "perl_version: $^V\n";
print "\033[0;35m Run Tests: \033[0m\n";
#print "perl_inc:\n".join("\n", @INC)."\n";


my $result=0;
foreach my $scr ( keys %$scrf ) {
	print "\033[0;36m selfcheck $scr \033[0m";
	my $wp="tmp/$scr";
	rmtree $wp;
	make_path "$wp/$configp/";
	write_text("$wp/$configp/startup", $startup);
	my $t;
	$t="$wp/$configp/scripts";
	`ln -s $wd/scripts.irssi.org/scripts/ $t`; #!!
	$t="$wp/selfcheckhelperscript.pl";
	`ln -s $wd/selfcheckhelperscript.pl $t`; #!!

	if ( exists $scrf->{$scr}->{branch} ) {
		`git -C $wd/scripts.irssi.org/ checkout $scrf->{$scr}->{branch} 2>/dev/null`;
		print " b:$scrf->{$scr}->{branch}";
	}

	chdir $wp;
	#$ENV{CURRENT_SCRIPT}=$scr;
	$ENV{CURRENT_SCRIPT}='print_signals';
	$ENV{USER}='action';
	#$ENV{TERM}='vt100';
	if ( $debug > 0 ) {
		system("irssi", "--home=$configp");
	} else {
		`irssi --home=$configp 2>stderr.log`;
	}
	chdir $wd;


	my ($info, $ires);
	if ( -e "$wp/info.yaml" ) {
		$info= LoadFile("$wp/info.yaml");
		$ires= $info->{selfcheckresult};
		if ( $ires eq 'ok' ) {
			print " $ires\n";
			next;
		}
	} 

	#print " $ires\n";
	#print "-------------\n";
	#system "cat", "$wp/info.yaml";
	#print "-------------\n";
	print "\n";
	system "tail", "$wp/selfcheck.log";
	#print "-------------\n";
	#system "cat", "$wp/stderr.log";
	$result=-1;
}

exit($result);
