use strict;
use warnings;
use Test::More tests => 3;
use FFI::Platypus;

subtest 'no arguments' => sub {
  plan tests => 2;
  my $ffi = FFI::Platypus->new;
  isa_ok $ffi, 'FFI::Platypus', 'FFI::Platypus.new';
  is_deeply [$ffi->lib], [], 'ffi.lib';
};

subtest 'with single lib' => sub {
  plan tests => 2;
  my $ffi = FFI::Platypus->new( lib => "libfoo.so" );
  isa_ok $ffi, 'FFI::Platypus', 'FFI::Platypus.new';
  is_deeply [$ffi->lib], ['libfoo.so'], 'ffi.lib';
};

subtest 'with multiple lib' => sub {
  plan tests => 2;
  my $ffi = FFI::Platypus->new( lib => ["libfoo.so", "libbar.so", "libbaz.so" ] );
  isa_ok $ffi, 'FFI::Platypus', 'FFI::Platypus.new';
  is_deeply [$ffi->lib], ['libfoo.so', 'libbar.so', 'libbaz.so'], 'ffi.lib';
};
