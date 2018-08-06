use strict;
use warnings;
use Test::More;
use FFI::Build::File::Object;
use Config ();

subtest 'basic' => sub {

  my $file = FFI::Build::File::Object->new(['corpus',"basic$Config::Config{obj_ext}"]);
  
  is($file->default_suffix, $Config::Config{obj_ext});
  is($file->default_encoding, ':raw');
  note "path = @{[ $file->path ]}";

};

done_testing;
