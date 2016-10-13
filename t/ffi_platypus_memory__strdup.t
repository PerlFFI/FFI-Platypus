use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Platypus::Memory;

my $ffi = FFI::Platypus->new;
$ffi->lib(undef);

note "strdup implementation = $FFI::Platypus::Memory::_strdup_impl";
my $ptr1 = malloc 32;
my $tmp  = strdup "this and\0";
memcpy $ptr1, $tmp, 9;
free $tmp;
my $string = $ffi->cast('opaque' => 'string', $ptr1);
is $string, 'this and', 'string = this and';
free $ptr1;
ok 1, 'free $ptr1';

done_testing;
