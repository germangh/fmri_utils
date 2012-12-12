#!/usr/bin/perl
# (c) German Gomez-Herrero, g.gomez@nin.knaw.nl

# Description: Uninstalls the FMRI module from the somerenserver
# Documentation: implementation.txt


use Cwd qw(abs_path cwd);
use File::Spec::Functions;
use File::Path qw(remove_tree);

my ($module, $bin_dir, $conf_dir) = (shift, shift, shift);
unless($bin_dir){$bin_dir = '/usr/local/bin';}
unless($module) {$module = '/usr/local/lib/perl5/site_perl/5.14.1/';}
unless($conf_dir) {$conf_dir = '/etc'};

my @files = qw(fmri_volume2matrix fmri_matrix2volume fmri_split_excel_stats);
my @files_bin = map {catdir($bin_dir, $_)} @files;
my @files_module = map {catfile($module, "$_.pl")} @files;

foreach (@files_bin, @files_module){ 
  unlink($_);
  print "unlink $_\n";
};

foreach (qw(fmri.ini)){
  my $file = catfile($conf_dir, $_);
  unlink $file;
  print "unlink $file\n";
}
# Remove the module directory
my $dir = catdir($module, 'fmri');
remove_tree $dir;
print "Removed $dir\n"
