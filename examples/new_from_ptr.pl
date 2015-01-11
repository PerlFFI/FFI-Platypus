use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus;

# The Declare interface does not allow creating functions
# from pointers, so we will use the OO interface instead.
my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib_or_exit lib => 'm');

my $address = $ffi->find_symbol('fmax'); # could also use DynaLoader or FFI::TinyCC

$ffi->attach([$address => 'fmax'] => ['double','double'] => 'double', '$$');

print fmax(2.0,4.0), "\n";
