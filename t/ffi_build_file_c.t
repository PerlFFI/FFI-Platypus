use strict;
use warnings;
use Test::More;
use FFI::Build::File::C;

subtest 'basic' => sub {

  my $file = FFI::Build::File::C->new(['corpus','basic.c']);
  
  is($file->default_suffix, '.c');
  is($file->default_encoding, ':utf8');

};

done_testing;
