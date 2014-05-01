use strict;
use warnings;
use Test::More tests => 6;
use FindBin ();
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'testlib');
use FFI::TestLib;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub ffi_closure );

my $void;
my $ptr;
my $int;

BEGIN {

  $void    = ffi_type c => 'void';
  $int     = ffi_type c => 'int';
  $ptr     = ffi_type c => '*void';
  my $config  = FFI::TestLib->config;
  my $testlib = ffi_lib $config->{lib};

  ffi_sub [$testlib], call_void_function => [$void, $ptr];
  ffi_sub [$testlib], call_int_function  => [$int,  $ptr];
}

my $counter = 0;
my $cb1 = ffi_closure(ffi_signature($void), sub { $counter++ });
isa_ok $cb1, 'FFI::Platypus::Closure';
call_void_function($cb1);
is $counter, 1, 'counter = 1';

my $cb2 = ffi_closure(ffi_signature($int), sub { 42 });
isa_ok $cb2, 'FFI::Platypus::Closure';
is call_int_function($cb2), 42, 'call_int_function';

my $cb3 = ffi_closure(ffi_signature(ffi_type c => 'int'), sub {});
isa_ok $cb3, 'FFI::Platypus::Closure';
do { no warnings;
  is call_int_function($cb3), 0, 'call_int_function with empty list';
};
