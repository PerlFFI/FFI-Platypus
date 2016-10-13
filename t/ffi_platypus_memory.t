use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Platypus::Memory;

my $ffi = FFI::Platypus->new;
$ffi->lib(undef);

# TODO: break this subtest up into one for
# malloc, calloc, memset and free
subtest 'malloc calloc memset free' => sub {
  my $ptr1 = malloc 22;
  ok $ptr1, "malloc returns $ptr1";
  memset $ptr1, 0, 22;
  memset $ptr1, ord 'x', 8;
  memset $ptr1, ord 'y', 4;
  my $ptr2 = calloc 9, $ffi->sizeof('char');
  ok $ptr2, "calloc returns $ptr2";
  my $string = $ffi->function(strcpy => ['opaque', 'opaque'] => 'string')->call($ptr2, $ptr1);
  is $string, 'yyyyxxxx', 'string = yyyyxxxx';
  free $ptr1;
  ok 1, 'free $ptr1';
  free $ptr2;
  ok 1, 'free $ptr2';
};

done_testing;
