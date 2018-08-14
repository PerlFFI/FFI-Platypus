use strict;
use warnings;
use Test::More tests => 2;

subtest C => sub {
  plan tests => 3;
  
  package
    Test1;

  use Test::More;  
  use FFI::Platypus::Declare;

  eval { type 'int' };
  is $@, '', 'int is an okay type';
  eval { type 'foo_t' };
  isnt $@, '', 'foo_t is not an okay type';
  note $@;
  eval { type 'sint16' };
  is $@, '', 'sint16 is an okay type';

};

subtest 'Foo constructor' => sub {
  plan tests => 5;

  package
    Test2;

  use Test::More;
  use FFI::Platypus::Declare;
  
  lang 'Foo';
  
  eval { type 'int' };
  isnt $@, '', 'int is not an okay type';
  note $@;
  eval { type 'foo_t' };
  is $@, '', 'foo_t is an okay type';
  eval { type 'sint16' };
  is $@, '', 'sint16 is an okay type';
  
  is sizeof('foo_t'), 2, 'sizeof foo_t = 2';
  is sizeof('bar_t'), 4, 'sizeof foo_t = 4';
  
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
