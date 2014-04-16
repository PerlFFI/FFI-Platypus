use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::Pod' 
    unless eval q{ use Test::Pod; 1 };
};
use Test::Pod;
use FindBin;
use File::Spec;

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

all_pod_files_ok( grep { -e $_ } qw( bin lib ));

