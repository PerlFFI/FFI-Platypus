use strict;
use warnings;
use Test::More skip_all => 'needs fixing!';
use Test::More tests => 2;
use FindBin ();
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'testlib');
use FFI::TestLib;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub ffi_closure );

BEGIN {

  my $config  = FFI::TestLib->config;
  my $testlib = ffi_lib $config->{lib};
  ffi_sub [$testlib], call_int_function  => [ffi_type c => 'int', ffi_type c => '*void'];
}

my $int = ffi_type c => 'int';

my $cb2 = ffi_closure(ffi_signature($int), sub { 42 });
isa_ok $int, 'FFI::Platypus::Type';
call_int_function($cb2);
isa_ok $int, 'FFI::Platypus::Type';
