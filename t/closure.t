use strict;
use warnings;
use Test::More tests => 2;
use FindBin ();
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'testlib');
use FFI::TestLib;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub ffi_closure );

my $void;
my $ptr;

BEGIN {

  $void    = ffi_type c => 'void';
  $ptr     = ffi_type c => '*void';
  my $config  = FFI::TestLib->config;
  my $testlib = ffi_lib $config->{lib};

  ffi_sub [$testlib], call_void_function => [$void, $ptr];
}

my $counter = 0;
my $cb1 = ffi_closure(ffi_signature($void), sub { $counter++ });

isa_ok $cb1, 'FFI::Platypus::Closure';

call_void_function($cb1);

is $counter, 1, 'counter = 1';
