use strict;
use warnings;
use Test::More tests => 2;
use FFI::Platypus;
use FFI::CheckLib;

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib lib => 'test', symbol => 'f2', libpath => 'libtest');

$ffi->attach('f2' => ['int*'] => 'void');
$ffi->attach([f2=>'f2_implicit'] => ['int*']);

my $i_ptr = 42;

f2(\$i_ptr);
is $i_ptr, 43, '$i_ptr = 43 after f2(\$i_ptr)';

f2_implicit(\$i_ptr);
is $i_ptr, 44, '$i_ptr = 44 after f2_implicit(\$i_ptr)';

