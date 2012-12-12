#!/usr/bin/perl
# (c) German Gomez-Herrero, g.gomez@nin.knaw.nl

# Description: Converts .matrix text files back to .nii volumes
# Documentation: implementation.txt

use Config::IniFiles;
use Getopt::Long;
use File::Spec::Functions;
use Cwd qw(abs_path cwd);

my $help;

my $ini = '/etc/fmri.ini';
my ($vol, $dir, $file) = File::Spec->splitpath($0);
if (-e abs_path(catfile($dir,'fmri.ini'))){
  $ini = abs_path(catfile($dir,'fmri.ini'));  
} 

GetOptions("conf=s"        => \$ini,
           "help=s"        => \$help);
			
my $folder = shift;

if ($help || !$folder){
  print "Usage: fmri_matrix2volume folder [--]
  --conf          location of the fmri.ini configuration file
  --help          displays this help\n";
  die "\n";
}


# Read configuration file
my $conf = new Config::IniFiles(-file => $ini);

# Run the MATLAB command
my $path = $conf->val('path', 'matlab_source');
my $cmd = 'matlab -nosplash -nodisplay -r "addpath(genpath(\''.$path.'\'));'. 
          'fmri.matrix2volume(\''.$folder.'\');exit;"';
`$cmd`;


