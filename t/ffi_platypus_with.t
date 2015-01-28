use strict;
use warnings;
use Test::More tests => 2;
use FFI::Platypus;

subtest C => sub {
  plan tests => 3;

  my $ffi = FFI::Platypus->new;
  eval { $ffi->type('int') };
  is $@, '', 'int is an okay type';
  eval { $ffi->type('foo_t') };
  isnt $@, '', 'foo_t is not an okay type';
  note $@;
  eval { $ffi->type('sint16') };
  is $@, '', 'sint16 is an okay type';

};

subtest 'Foo' => sub {
  plan tests => 5;

  my $ffi = FFI::Platypus->new(with => 'Foo');
  
  eval { $ffi->type('int') };
  isnt $@, '', 'int is not an okay type';
  note $@;
  eval { $ffi->type('foo_t') };
  is $@, '', 'foo_t is an okay type';
  eval { $ffi->type('sint16') };
  is $@, '', 'sint16 is an okay type';
  
  is $ffi->sizeof('foo_t'), 2, 'sizeof foo_t = 2';
  is $ffi->sizeof('bar_t'), 4, 'sizeof foo_t = 4';
  
};

package
  FFI::Platypus::Lang::Foo;

sub native_type_map
{
  {
    foo_t => 'sint16',
    bar_t => 'uint32',
  }
}
