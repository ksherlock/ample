use strict;
use Getopt::Long;
use Data::Dumper;

my $file;
my @rpaths;
my $path;
my $verbose = 0;
my $help = 0;
my $dry_run = 0;

sub help($) {
	print("Usage: install_name_tool.pl [--dry-run] [--verbose] exec-file rpath\n");
	exit(shift);
}

sub uniq {
	my %seen;
	grep !$seen{$_}++, @_;
}

GetOptions("help" => \$help, "verbose" => \$verbose, "dry-run" => \$dry_run);
help(0) if $help;
$verbose = 1 if $dry_run;

help(1) unless scalar(@ARGV) == 2;
($file, $path) = @ARGV;


open(my $fh, "-|", "otool", "-l", $file);


#
#Load command 33
#          cmd LC_RPATH
#      cmdsize 32
#         path ./Frameworks/ (offset 12)
#
#


my $cmd = '';
while (<$fh>) {
	chomp;
	if ($_ =~ /^Load command/) {
		$cmd = '';
		next;
	}
	if ($_ =~ /^\s+cmd ([A-Z_]+)$/) {
		$cmd = $1;
		next;
	}
	if ($cmd eq 'LC_RPATH' && $_ =~ /^\s+path (.+) \(offset \d+\)$/) {
		push(@rpaths, $1);
	}
}
close($fh);

@rpaths = uniq(@rpaths);

if ($verbose) {
	print "current rpaths:\n";
	foreach(@rpaths) {
		print($_ . "\n");
	}
}

my @args;

# grrr... -change doesn't seem to work anymore.
# equal or changeable.
if (scalar @rpaths == 1) {
	exit(0) if $rpaths[0] eq $path;
#	push(@args, ("-change", ${rpaths[0]}, $path))
}
#} else {
if (1) {

	my @tmp;
	@tmp = grep {$_ ne $path } @rpaths;

	foreach  (@tmp) {
		push(@args, ("-delete_rpath", $_))
	}


	@tmp = grep {$_ eq $path } @rpaths;
	if (!scalar @tmp) {
		push(@args, ("-add_rpath", $path));
	}
}

if (scalar @args) {
	print( join(' ', "install_name_tool", @args, $file) . "\n") if $verbose;
	exit(0) if $dry_run;
	system("install_name_tool", @args, $file);
	exit($?);
}
exit(0);
