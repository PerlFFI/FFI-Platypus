use strict;
use warnings;
use Test::More tests => 3;
use File::Spec;
use FFI::Platypus;
use FFI::CheckLib;

my $ffi = FFI::Platypus->new;

my($lib) = find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';
ok -e $lib, "exists $lib";

eval { $ffi->lib($lib) };
is $@, '', 'ffi.lib (set)';

is_deeply [eval { $ffi->lib }], [$lib], 'ffi.lib (get)';
