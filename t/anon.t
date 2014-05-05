use strict;
use warnings;
use Test::More tests => 2;
use FindBin ();
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'testlib');
use FFI::TestLib;
use FFI::Platypus qw( ffi_type ffi_signature ffi_lib ffi_sub ffi_meta );

# return_passed_integer_value

my $int   = ffi_type c => 'int';
my $config = FFI::TestLib->config;
my $testlib = ffi_lib $config->{lib};

my $ffi_sub = ffi_sub [$testlib], [ return_passed_integer_value => undef ], [$int,$int];

isa_ok $ffi_sub, 'FFI::Platypus::Sub';
note "lib_name  = ", $ffi_sub->lib_name;
note "perl_name = ", $ffi_sub->perl_name;

is $ffi_sub->coderef->(42), 42, 'can call via coderef';
