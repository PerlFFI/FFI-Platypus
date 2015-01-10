use strict;
use warnings;
use Test::More tests => 3;
use FFI::Platypus;
use FFI::Platypus::Memory qw( sizeof malloc calloc memset free realloc memcpy );

my $ffi = FFI::Platypus->new;
$ffi->lib(undef);

subtest 'sizeof' => sub {
  plan tests => 2;
  is sizeof 'uint32', 4, 'sizeof uint32 = 4';
  is sizeof 'uint32[2]', 8, 'sizeof uint32[2] = 8';
};

subtest 'malloc calloc memset free' => sub {
  plan tests => 1;
  my $ptr1 = malloc 22;
  memset $ptr1, 0, 22;
  memset $ptr1, ord 'x', 8;
  memset $ptr1, ord 'y', 4;
  my $ptr2 = calloc 9, sizeof 'char';
  my $string = $ffi->function(strcpy => ['pointer', 'pointer'] => 'string')->call($ptr2, $ptr1);
  is $string, 'yyyyxxxx', 'string = yyyyxxxx';
  free $ptr1;
  free $ptr2;
};

subtest 'realloc memcpy free' => sub {
  my $ptr1 = realloc undef, 32;
  my $tmp  = realloc undef, 64;
  $ffi->function(strcpy => ['pointer', 'string'] => 'pointer')->call($tmp, "this and\0");
  memcpy $ptr1, $tmp, 9;
  free $tmp;
  my $tmp2 = realloc undef, 128;
  my $string = $ffi->function(strcpy => ['pointer', 'pointer'] => 'string')->call($tmp2, $ptr1);
  is $string, 'this and', 'string = this and';
  free $ptr1;
  free $tmp2;
};
