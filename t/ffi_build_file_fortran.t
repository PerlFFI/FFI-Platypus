use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::Cleanup;
use FFI::Build::File::Fortran;
use FFI::Build;
use FFI::Build::Platform;
use Capture::Tiny qw( capture_merged );

plan skip_all => 'Test requires Fortran compiler'
  unless eval { FFI::Build::Platform->which(FFI::Build::Platform->for) };

subtest 'basic' => sub {

  my $file = FFI::Build::File::Fortran->new(['corpus', 'ffi_build_file_fortran', 'add.f']);
  
  isa_ok $file, 'FFI::Build::File::Fortran';
  isa_ok $file, 'FFI::Build::File::C';
  isa_ok $file, 'FFI::Build::File::Base';
  is($file->default_suffix, '.f');
  is($file->default_encoding, ':utf8');

};

subtest 'compile' => sub {

  my $file = FFI::Build::File::Fortran->new([qw( corpus ffi_build_file_fortran add.f )]);
  my $object = $file->build_item;
  isa_ok $object, 'FFI::Build::File::Object';
  
  is_deeply
    [ $object->build_item ],
    [];

  cleanup 'corpus/ffi_build_file_fortran/_build';

};

done_testing;
