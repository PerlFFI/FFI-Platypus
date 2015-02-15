use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'longdouble';

plan skip_all => 'test requires support for long double'
  unless FFI::Platypus::_have_type('longdouble');

plan tests => 2;

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';
attach [longdouble_add => 'add'] => [longdouble,longdouble] => longdouble;

subtest 'with Math::LongDouble' => sub {
  plan skip_all => 'test requires Math::LongDouble'
    unless eval q{ use Math::LongDouble; 1 };
  plan tests => 2;
  
  my $ld15 = Math::LongDouble->new(1.5);
  my $ld25 = Math::LongDouble->new(2.5);
  my $ld40 = Math::LongDouble->new(4.0);
  my $result = add($ld15, $ld25);
  isa_ok $result, 'Math::LongDouble';
  ok $result == $ld40, "add(1.5,2.5) = 4.0";
};

subtest 'without Math::LongDouble' => sub {
  plan tests => 1;

  if(FFI::Platypus::_have_math_longdouble())
  {
    note "You have Math::LongDouble, but for this test we are going to turn it off";
    FFI::Platypus::_have_math_longdouble(0);
  }
  
  is add(1.5, 2.5), 4.0, "add(1.5,2.5) = 4";
};
