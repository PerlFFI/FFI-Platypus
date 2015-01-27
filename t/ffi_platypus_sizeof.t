use strict;
use warnings;
use Test::More tests => 5;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;

subtest integers => sub {
  plan tests => 8;
  is $ffi->sizeof('uint8'), 1, 'sizeof uint8 = 1';
  is $ffi->sizeof('uint16'), 2, 'sizeof uint16 = 2';
  is $ffi->sizeof('uint32'), 4, 'sizeof uint32 = 4';
  is $ffi->sizeof('uint64'), 8, 'sizeof uint64 = 8';

  is $ffi->sizeof('sint8'), 1, 'sizeof sint8 = 1';
  is $ffi->sizeof('sint16'), 2, 'sizeof sint16 = 2';
  is $ffi->sizeof('sint32'), 4, 'sizeof sint32 = 4';
  is $ffi->sizeof('sint64'), 8, 'sizeof sint64 = 8';
};

subtest floats => sub {
  plan tests => 2;
  is $ffi->sizeof('float'), 4, 'sizeof float = 4';
  is $ffi->sizeof('double'), 8, 'sizeof double = 8';
};

subtest pointers => sub {
  plan tests => 14;
  my $pointer_size = $ffi->sizeof('opaque');
  ok $pointer_size == 4 || $pointer_size == 8, "sizeof opaque = $pointer_size";
  
  is $ffi->sizeof('uint8*'), $pointer_size, "sizeof uint8* = $pointer_size";
  is $ffi->sizeof('uint16*'), $pointer_size, "sizeof uint16* = $pointer_size";
  is $ffi->sizeof('uint32*'), $pointer_size, "sizeof uint32* = $pointer_size";
  is $ffi->sizeof('uint64*'), $pointer_size, "sizeof uint64* = $pointer_size";

  is $ffi->sizeof('sint8*'), $pointer_size, "sizeof sint8* = $pointer_size";
  is $ffi->sizeof('sint16*'), $pointer_size, "sizeof sint16* = $pointer_size";
  is $ffi->sizeof('sint32*'), $pointer_size, "sizeof sint32* = $pointer_size";
  is $ffi->sizeof('sint64*'), $pointer_size, "sizeof sint64* = $pointer_size";
  
  is $ffi->sizeof('float*'), $pointer_size, "sizeof float* = $pointer_size";
  is $ffi->sizeof('double*'), $pointer_size, "sizeof double* = $pointer_size";
  is $ffi->sizeof('opaque*'), $pointer_size, "sizeof opaque* = $pointer_size";
  
  is $ffi->sizeof('string'), $pointer_size, "sizeof string = $pointer_size";
  is $ffi->sizeof('(int)->int'), $pointer_size, "sizeof (int)->int = $pointer_size";
};

subtest arrays => sub {
  plan tests => 110;

  foreach my $type (qw( uint8 uint16 uint32 uint64 sint8 sint16 sint32 sint64 float double opaque ))
  {
    my $unit_size = $ffi->sizeof($type);
    foreach my $size (1..10)
    {
      is $ffi->sizeof("$type [$size]"), $unit_size*$size, "sizeof $type [32] = @{[$unit_size*$size]}";
    }
  }

};

subtest custom_type => sub {

  foreach my $type (qw( uint8 uint16 uint32 uint64 sint8 sint16 sint32 sint64 float double opaque ))
  {
    my $expected = $ffi->sizeof($type);
    $ffi->custom_type( "my_$type" => { native_type => $type, native_to_perl => sub {} } );
    is $ffi->sizeof("my_$type"), $expected, "sizeof my_$type = $expected";
  }
};
