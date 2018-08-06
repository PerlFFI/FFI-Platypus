use strict;
use warnings;
use Test::More;
use FFI::Build::File::Library;
use Config ();

my $dlext = $^O eq 'MSWin32' ? '.dll' : ".$Config::Config{dlext}";

subtest 'basic' => sub {

  my $file = FFI::Build::File::Library->new(['corpus',"basic$dlext"]);
  
  is($file->default_suffix, $dlext);
  is($file->default_encoding, ':raw');
  note "path = @{[ $file->path ]}";

};

done_testing;
