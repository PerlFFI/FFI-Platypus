use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Platypus::Memory;

my $ffi = FFI::Platypus->new;
$ffi->lib(undef);

my $ptr1 = malloc 64;
my $ptr2 = malloc 64;
$ffi->function(strcpy => ['opaque', 'string'] => 'opaque')->call($ptr1, "starscream");
is( $ffi->cast('opaque','string', $ptr1), "starscream", "initial data copied" );
my $ret = memcpy $ptr2, $ptr1, 64;
is( $ffi->cast('opaque','string', $ptr2), "starscream", "copy of copy" );
is $ret, $ptr2, "memcpy returns a pointer";
free $ptr1;
ok 1, 'free $ptr1';
free $ptr2;
ok 1, 'free $ptr2';

done_testing;
