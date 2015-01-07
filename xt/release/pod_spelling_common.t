use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::Pod::Spelling::CommonMistakes' 
    unless eval q{ use Test::Pod::Spelling::CommonMistakes; 1 };
  plan skip_all => 'test requires YAML'
    unless eval q{ use YAML qw( LoadFile ); 1 };
};
use Test::Pod::Spelling::CommonMistakes;
use FindBin;
use File::Spec;

my $config_filename = File::Spec->catfile(
  $FindBin::Bin, 'release.yml'
);

my $config;
$config = LoadFile($config_filename)
  if -r $config_filename;

plan skip_all => 'disabled' if $config->{pod_spelling_common}->{skip};

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

# FIXME test files in bin too.
all_pod_files_ok;
