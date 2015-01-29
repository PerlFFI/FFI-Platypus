use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus;

subtest 'Foo constructor' => sub {
  plan tests => 5;

  my $ffi = FFI::Platypus->new(lang => 'Rust');
  
  eval { $ffi->type('int') };
  isnt $@, '', 'int is not an okay type';
  note $@;
  eval { $ffi->type('i32') };
  is $@, '', 'foo_t is an okay type';
  eval { $ffi->type('sint16') };
  is $@, '', 'sint16 is an okay type';
  
  is $ffi->sizeof('i16'), 2, 'sizeof foo_t = 2';
  is $ffi->sizeof('u32'), 4, 'sizeof foo_t = 4';
  
};

