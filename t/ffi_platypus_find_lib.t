use strict;
use warnings;
use Test::More tests => 1;
use File::Spec;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;
$ffi->find_lib(lib => 'test', symbol => 'f0', libpath => 'libtest');
my $address = $ffi->find_symbol('f0');
ok $address, "found f0 = $address";
