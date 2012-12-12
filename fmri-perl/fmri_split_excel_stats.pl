#!/usr/bin/perl

# A command-line wrapper for MATLAB utility +fmri/split_excel_stats
# German Gomez-Herrero, g.gomez@nin.knaw.nl

use Config::IniFiles;
use Getopt::Long;
use File::Spec::Functions;
use Cwd qw(abs_path getcwd);

my $help;

my $ini = '/etc/fmri.ini';
my ($vol, $dir, $file) = File::Spec->splitpath($0);
if (-e abs_path(catfile($dir,'fmri.ini'))){
  $ini = abs_path(catfile($dir,'fmri.ini'));  
} 

GetOptions("conf=s"        => \$ini,
           "help=s"        => \$help);
	

my $fName  = shift;
my $hRow   = shift;
my $oFName = shift;
my $sCol   = shift;
my @grpArgs = @ARGV;	

foreach (@grpArgs)
{
	$_ = join('\',\'', split(',', $_));
}

my $grpArgs = join('\'},{\'', @grpArgs);
$grpArgs    = '{\''.$grpArgs.'\'}';

if ($help || !$fName || !$hRow || !$sCol || !$oFName){
  print "Usage: fmri_split_excel_stats fName hRow oFName sCol cGrp1 cGrp2 ... [--]
  
  --conf          location of the fmri.ini configuration file
  --help          displays this help  
  
  ## Example:
  
  fmri_split_excel_stats test.xls 1 \\
	\"test_<?subj>_<?set>.txt\" subject stat1 stat2,stat3
  
  which will generate 2 text files per subject. Assuming there was only one
  subject with ID 0001 then the generated files will be named:
  
  0001_st1.txt
  0001_st2-st3.txt
  
  The former will contain a single column of values (stat1) while the latter
  will contain two columns (stat2 and stat3) 
  
  \n";
  die "\n";
}

# Read configuration file
my $conf = new Config::IniFiles(-file => $ini);

# Run the MATLAB command
my $path = $conf->val('path', 'matlab_source');
my $cwd = getcwd;
my $cmd = 'matlab -nosplash -nodisplay -r "cd \''.$cwd.'\';addpath(genpath(\''.$path.'\'));'. 
          "try ".
		  'fmri.split_excel_stats(\''.$fName.'\','. 
		  ''.$hRow.',\''.$oFName.'\',\''.$sCol.'\','.$grpArgs.');'.
          "catch ME exit; end ".
		  'exit;"';
		
print "$cmd\n";
system($cmd);
#system($cmd);




