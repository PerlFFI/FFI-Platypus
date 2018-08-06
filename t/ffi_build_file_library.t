use strict;
use warnings;
use Test::More;
use FFI::Build::File::Library;
use Config ();

subtest 'basic' => sub {

  my $file = FFI::Build::File::Library->new(['corpus',".basic$Config::Config{dlext}"]);
  
  is($file->default_suffix, ".$Config::Config{dlext}");
  is($file->default_encoding, ':raw');
  note "path = @{[ $file->path ]}";

};

done_testing;
