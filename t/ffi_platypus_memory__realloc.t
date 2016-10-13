use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Platypus::Memory;

my $ffi = FFI::Platypus->new;
$ffi->lib(undef);

my $ptr = realloc undef, 32;
ok $ptr, "realloc call ptr = @{[ $ptr ]}";
$ffi->function(strcpy => ['opaque', 'string'] => 'opaque')->call($ptr, "hello");
is( $ffi->cast('opaque','string', $ptr), "hello", "initial data copied" );
$ptr = realloc $ptr, 1024*5;
ok $ptr, "realloc call ptr = @{[ $ptr ]} (2)";
is( $ffi->cast('opaque','string', $ptr), "hello", "after realloc data there" );
free $ptr;
ok 1, 'final free';

done_testing;
