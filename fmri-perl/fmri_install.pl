#!/usr/bin/perl
# (c) German Gomez-Herrero, g.gomez@nin.knaw.nl

# Description: Installs the FMRI module at the somerenserver
# Documentation: implementation.txt


use Cwd qw(abs_path cwd);
use File::Spec::Functions;
use File::Copy::Recursive qw(dircopy);
use File::Copy;

my ($module, $bin_dir, $conf_dir) = (shift, shift, shift);

unless($bin_dir){ $bin_dir = '/usr/local/bin' };
unless($module) {$module = '/usr/local/lib/perl5/site_perl/5.14.1/'};
unless($conf_dir) {$conf_dir = '/etc'};

# Copy module into destination directory
my $dir_from = cwd();
my $dir_to   = catdir($module,'fmri');
dircopy($dir_from, $dir_to) or die "Copy $dir_from --> $dir_to failed: $!"; 
print "dircopy $dir_from $dir_to\n";
chmod (0755, catdir($module,'fmri')) or die "Coudn't chmod $file: $!";
        
# Copy scripts to the perl libraries directory and generate symbolic links to them
foreach (qw(fmri_matrix2volume fmri_volume2matrix fmri_split_excel_stats)){
  my $file = catfile($module, 'fmri', $_.'.pl');
  copy($_.'.pl', $file) or die "Copy $_.pl -> $file failed: $!";
  print "copy $_.pl $file\n";
  chmod (0755, $file) or die "Coudn't chmod $file: $!";  
  my $link_name = catfile($bin_dir, $_);
  symlink $file, $link_name;
  print "symlink $file $link_name\n";
}

foreach (qw(fmri.ini)){
  my $file = catfile($module, 'fmri', $_);
  copy($_, $file ) or die "Copy $_ --> $file failed: $!";
  print "copy $_ $file\n";
  my $link_name = catfile($conf_dir, $_);
  symlink $file, $link_name;
  print "symlink $file $link_name\n";
  chmod (0755, $file) or die "Coudn't chmod $file: $!";
}  
