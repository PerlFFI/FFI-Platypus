use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::Pod::Spelling::CommonMistakes' 
    unless eval q{ use Test::Pod::Spelling::CommonMistakes; 1 };
};
use Test::Pod::Spelling::CommonMistakes;
use FindBin;
use File::Spec;

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

# FIXME test files in bin too.
all_pod_files_ok;
