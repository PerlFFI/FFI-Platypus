use strict;
use warnings;
use Test::More tests => 15;
use FindBin ();
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'testlib');
use FFI::TestLib;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub ffi_closure );

my $void;
my $ptr;
my $int;
my $size_t;

BEGIN {

  $void    = ffi_type c => 'void';
  $int     = ffi_type c => 'int';
  $ptr     = ffi_type c => '*void';
  $size_t  = ffi_type c => 'size_t';
  my $config  = FFI::TestLib->config;
  my $testlib = ffi_lib $config->{lib};

  ffi_sub [$testlib], call_void_function => [$void, $ptr];
  ffi_sub [$testlib], call_int_function  => [$int,  $ptr];
  ffi_sub [$testlib], call_ptr_function  => [$ptr,  $ptr];
  
  ffi_sub [], malloc => [$ptr, $size_t];
  ffi_sub [], free   => [$void, $ptr];
}

my $counter = 0;
my $cb1 = ffi_closure(ffi_signature($void), sub { $counter++ });
isa_ok $cb1, 'FFI::Platypus::Closure';
call_void_function($cb1);
is $counter, 1, 'counter = 1';

my $cb2 = ffi_closure(ffi_signature($int), sub { 42 });
isa_ok $cb2, 'FFI::Platypus::Closure';
is call_int_function($cb2), 42, 'call_int_function';

my $cb3 = ffi_closure(ffi_signature($int), sub {});
isa_ok $cb3, 'FFI::Platypus::Closure';
do { no warnings;
  is call_int_function($cb3), 0, 'call_int_function with empty list';
};

my $cb4 = ffi_closure(ffi_signature($ptr), sub { undef });
isa_ok $cb4, 'FFI::Platypus::Closure';
is call_ptr_function($cb4), undef, 'call_ptr_function with undef';

my $cb5 = ffi_closure(ffi_signature($ptr), sub { 0 });
isa_ok $cb5, 'FFI::Platypus::Closure';
is call_ptr_function($cb5), undef, 'call_ptr_function with 0';

my $cb6 = ffi_closure(ffi_signature($ptr), sub { });
isa_ok $cb6, 'FFI::Platypus::Closure';
is call_ptr_function($cb6), undef, 'call_ptr_function with empty list';

my $foo = malloc(10);
my $cb7 = ffi_closure(ffi_signature($ptr), sub { $foo });
isa_ok $cb7, 'FFI::Platypus::Closure';
is call_ptr_function($cb7), $foo, 'call_ptr_function with real pointer';
free($foo);

$foo = $cb1;
call_void_function(call_ptr_function($cb7));
is $counter, 2, 'counter = 2';
