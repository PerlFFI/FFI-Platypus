use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::EOL' 
    unless eval q{ use Test::EOL; 1 };
};
use Test::EOL;
use FindBin;
use File::Spec;

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

all_perl_files_ok(grep { -e $_ } qw( bin lib t Makefile.PL ));
