use strict;
use warnings;
use Test::More;
use FFI::Platypus qw( ffi_lib );

plan skip_all => 'set FFI_PLATYPUS_TEST_LIBARCHIVE to location of libarchive.so or archive.dll'
  unless $ENV{FFI_PLATYPUS_TEST_LIBARCHIVE};

plan tests => 2;

my $libarchive = ffi_lib $ENV{FFI_PLATYPUS_TEST_LIBARCHIVE};
isa_ok $libarchive, 'FFI::Platypus::Lib';
is $libarchive->path_name, $ENV{FFI_PLATYPUS_TEST_LIBARCHIVE}, "libarchive.path_name = $ENV{FFI_PLATYPUS_TEST_LIBARCHIVE}";
note "refcount  = ", $libarchive->_refcount if $libarchive->can('_refcount');
note "handle    = ", $libarchive->_handle   if $libarchive->can('_handle');
