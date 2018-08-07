use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::Cleanup;
use FFI::Build::File::C;
use FFI::Build;
use Capture::Tiny qw( capture_merged );

subtest 'basic' => sub {

  my $file = FFI::Build::File::C->new(['corpus','basic.c']);
  
  isa_ok $file, 'FFI::Build::File::C';
  isa_ok $file, 'FFI::Build::File::Base';
  is($file->default_suffix, '.c');
  is($file->default_encoding, ':utf8');

};

subtest 'compile' => sub {

  my $file = FFI::Build::File::C->new([qw( corpus ffi_build_file_c foo1.c )]);
  my $object = $file->build;
  isa_ok $object, 'FFI::Build::File::Object';
  
  is_deeply
    [ $object->build ],
    [];

  cleanup 'corpus/ffi_build_file_c/_build';

};

subtest 'headers' => sub {

  my $lib = FFI::Build->new('foo',
    verbose => 1,
    cflags  => "-Icorpus/ffi_build_file_c/include",
  );

  note "cflags=$_" for @{ $lib->cflags };

  my $file = FFI::Build::File::C->new([qw( corpus ffi_build_file_c foo2.c )], library => $lib );
  
  my @deps = eval { $file->_deps };
  is $@, '', 'no die';

  foreach my $dep (@deps)
  {
    ok -f "$dep", "dep is afile: $dep";
  }
  
};

done_testing;
