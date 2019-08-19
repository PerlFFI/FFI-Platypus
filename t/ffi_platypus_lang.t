use strict;
use warnings;
use Test::More;
use FFI::Platypus::Lang;
use FFI::CheckLib;
use FFI::Platypus;

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

subtest 'Foo constructor' => sub {
  my $ffi = FFI::Platypus->new(lang => 'Foo');
  $ffi->lib($libtest);

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
  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);
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

subtest 'MyLang::Roger' => sub {

  my $ffi = FFI::Platypus->new;
  $ffi->lang('=MyLang::Roger');

  eval { $ffi->type('int') };
  isnt $@, '', 'int is not an okay type';
  note $@;

  is $ffi->sizeof('foo_t'), 4, 'sizeof foo_t = 4';

};

done_testing;

package
  MyLang::Roger;

sub native_type_map
{
  {
    foo_t => 'sint32',
  }
}

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
  die "not a class method of FFI::Platypus::Lang::Foo"
    unless $_[0] eq 'FFI::Platypus::Lang::Foo';
  die "libtest not passed in as second argument"
    unless $_[1] eq $libtest;

  my %mangle = (
    'UnMangled::Name(int i)' => 'f0',
  );

  sub {
    defined $mangle{$_[0]} ? $mangle{$_[0]} : $_[0];
  };
}

