use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::Spelling' 
    unless eval q{ use Test::Spelling; 1 };
  plan skip_all => 'test requires YAML'
    unless eval q{ use YAML; 1; };
};
use Test::Spelling;
use YAML qw( LoadFile );
use FindBin;
use File::Spec;

my $config_filename = File::Spec->catfile(
  $FindBin::Bin, 'release.yml'
);

my $config;
$config = LoadFile($config_filename)
  if -r $config_filename;

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

add_stopwords(@{ $config->{pod_spelling_system}->{stopwords} });
add_stopwords(<DATA>);
all_pod_files_spelling_ok;

__DATA__
Plicease
stdout
stdin
subref
loopback
username
os
Ollis
Mojolicious
plicease
