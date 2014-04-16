use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::NoTabs' 
    unless eval q{ use Test::NoTabs; 1 };
};
use Test::NoTabs;
use FindBin;
use File::Spec;

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

all_perl_files_ok( grep { -e $_ } qw( bin lib t Makefile.PL ));

