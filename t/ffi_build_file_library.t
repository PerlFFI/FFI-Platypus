use strict;
use warnings;
use Test::More;
use FFI::Build::File::Library;
use Config ();

my $dll = FFI::Build::Platform->library_suffix;

subtest 'basic' => sub {

  my $file = FFI::Build::File::Library->new(['corpus',"basic$dll"]);
  
  is($file->default_suffix, $dll);
  is($file->default_encoding, ':raw');
  note "path = @{[ $file->path ]}";

};

done_testing;
