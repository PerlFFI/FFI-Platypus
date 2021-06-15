use Test2::V0 -no_srand => 1;
use FFI::Build::File::Object;

my $o = FFI::Build::Platform->object_suffix;

subtest 'basic' => sub {

  my $file = FFI::Build::File::Object->new(['corpus',"basic$o"]);

  is($file->default_suffix, $o);
  is($file->default_encoding, ':raw');
  note "path = @{[ $file->path ]}";

};

done_testing;
