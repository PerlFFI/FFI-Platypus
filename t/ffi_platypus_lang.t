use strict;
use warnings;
use Test::More tests => 3;
use FFI::CheckLib;
use FFI::Platypus;

subtest C => sub {
  plan tests => 4;

  my $ffi = FFI::Platypus->new;
  $ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 'libtest');

  eval { $ffi->type('int') };
  is $@, '', 'int is an okay type';
  eval { $ffi->type('foo_t') };
  isnt $@, '', 'foo_t is not an okay type';
  note $@;
  eval { $ffi->type('sint16') };
  is $@, '', 'sint16 is an okay type';

  is $ffi->find_symbol('UnMangled::Name(int i)'), undef, 'unable to find unmangled name';

};

subtest 'Foo constructor' => sub {
  plan tests => 6;

  my $ffi = FFI::Platypus->new(lang => 'Foo');
  $ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 'libtest');
  
  eval { $ffi->type('int') };
  isnt $@, '', 'int is not an okay type';
  note $@;
  eval { $ffi->type('foo_t') };
  is $@, '', 'foo_t is an okay type';
  eval { $ffi->type('sint16') };
  is $@, '', 'sint16 is an okay type';
  
  is $ffi->sizeof('foo_t'), 2, 'sizeof foo_t = 2';
  is $ffi->sizeof('bar_t'), 4, 'sizeof foo_t = 4';

  is $ffi->function('UnMangled::Name(int i)' => ['myint'] => 'myint')->call(22), 22;
  
};

subtest 'Foo attribute' => sub {
  plan tests => 6;

  my $ffi = FFI::Platypus->new;
  $ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 'libtest');
  $ffi->lang('Foo');
  
  eval { $ffi->type('int') };
  isnt $@, '', 'int is not an okay type';
  note $@;
  eval { $ffi->type('foo_t') };
  is $@, '', 'foo_t is an okay type';
  eval { $ffi->type('sint16') };
  is $@, '', 'sint16 is an okay type';
  
  is $ffi->sizeof('foo_t'), 2, 'sizeof foo_t = 2';
  is $ffi->sizeof('bar_t'), 4, 'sizeof foo_t = 4';
  
  is $ffi->function('UnMangled::Name(int i)' => ['myint'] => 'myint')->call(22), 22;
};

package
  FFI::Platypus::Lang::Foo;

sub native_type_map
{
  {
    foo_t => 'sint16',
    bar_t => 'uint32',
    myint => 'sint32',
  }
}

sub mangler
{
  my %mangle = (
    'UnMangled::Name(int i)' => 'f0',
  );
  
  sub {
    defined $mangle{$_[0]} ? $mangle{$_[0]} : $_[0];
  };
}
