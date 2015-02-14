use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'longdouble';

plan skip_all => 'test requires support for long double'
  unless FFI::Platypus::_have_type('longdouble');

plan tests => 1;

if(FFI::Platypus::_have_math_longdouble())
{
  note "You have Math::LongDouble, but for this test we are going to turn it off";
  FFI::Platypus::_have_math_longdouble(0);
}

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

attach [longdouble_add => 'add'] => [longdouble,longdouble] => longdouble;

is add(1.5, 2.5), 4.0, "add(1.5,2.5) = 4";
