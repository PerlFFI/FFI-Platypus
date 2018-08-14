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

subtest 'memcpy' => sub {
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
};

subtest 'realloc' => sub {
  my $ptr = realloc undef, 32;
  ok $ptr, "realloc call ptr = @{[ $ptr ]}";
  $ffi->function(strcpy => ['opaque', 'string'] => 'opaque')->call($ptr, "hello");
  is( $ffi->cast('opaque','string', $ptr), "hello", "initial data copied" );
  $ptr = realloc $ptr, 1024*5;
  ok $ptr, "realloc call ptr = @{[ $ptr ]} (2)";
  is( $ffi->cast('opaque','string', $ptr), "hello", "after realloc data there" );
  free $ptr;
  ok 1, 'final free';
};

subtest 'strdup' => sub {
  note "strdup implementation = $FFI::Platypus::Memory::_strdup_impl";
  my $ptr1 = malloc 32;
  my $tmp  = strdup "this and\0";
  memcpy $ptr1, $tmp, 9;
  free $tmp;
  my $string = $ffi->cast('opaque' => 'string', $ptr1);
  is $string, 'this and', 'string = this and';
  free $ptr1;
  ok 1, 'free $ptr1';
};

done_testing;
