use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib;

BEGIN {
  plan skip_all => 'test requires support for long double'
    unless FFI::Platypus::_have_type('longdouble');
}

use FFI::Platypus::Declare
  'longdouble', 'int', 
  ['longdouble*' => 'longdouble_p'],
  ['longdouble[3]' => 'longdouble_a3' ],
  ['longdouble[]'  => 'longdouble_a'  ];

plan tests => 2;

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';
attach [longdouble_add => 'add'] => [longdouble,longdouble] => longdouble;
attach longdouble_pointer_test => [longdouble_p, longdouble_p] => int;
attach longdouble_array_test => [longdouble_a, int] => int;
attach [longdouble_array_test => 'longdouble_array_test3'] => [longdouble_a3, int] => int;
attach longdouble_array_return_test => [] => longdouble_a3;
attach pointer_is_null => [longdouble_p] => int;
attach longdouble_pointer_return_test => [longdouble] => longdouble_p;
attach pointer_null => [] => longdouble_p;

subtest 'with Math::LongDouble' => sub {
  plan skip_all => 'test requires Math::LongDouble'
    unless eval q{ use Math::LongDouble; 1 };
  plan tests => 5;
  
  my $ld15 = Math::LongDouble->new(1.5);
  my $ld25 = Math::LongDouble->new(2.5);
  my $ld40 = Math::LongDouble->new(4.0);
  my $ld80 = Math::LongDouble->new(8.0);

  subtest 'scalar' => sub {
    plan tests => 2;
    my $result = add($ld15, $ld25);
    isa_ok $result, 'Math::LongDouble';
    ok $result == $ld40, "add(1.5,2.5) = 4.0";
  };
  
  subtest 'pointer' => sub {
    plan tests => 6;
    my $a = Math::LongDouble->new(1.5);
    my $b = Math::LongDouble->new(2.5);
    ok longdouble_pointer_test(\$a, \$b);
    ok $a == $ld40;
    ok $b == $ld80;
    ok pointer_is_null(undef);
    
    my $c = longdouble_pointer_return_test($ld15);
    isa_ok $$c, 'Math::LongDouble';
    ok $$c == $ld15;
  };
  
  my $ld10 = Math::LongDouble->new(1.0);
  my $ld20 = Math::LongDouble->new(2.0);
  my $ld30 = Math::LongDouble->new(3.0);

  subtest 'array fixed' => sub {
    plan tests => 4;
    my $list = [ map { Math::LongDouble->new($_) } qw( 25.0 25.0 50.0 )];
    
    ok longdouble_array_test3($list, 3);
    note "[", join(',', map { "$_" } @$list), "]";
    ok $list->[0] == $ld10;
    ok $list->[1] == $ld20;
    ok $list->[2] == $ld30;
  };

  subtest 'array var' => sub {
    plan tests => 4;
    my $list = [ map { Math::LongDouble->new($_) } qw( 25.0 25.0 50.0 )];
    
    ok longdouble_array_test($list, 3);
    note "[", join(',', map { "$_" } @$list), "]";
    ok $list->[0] == $ld10;
    ok $list->[1] == $ld20;
    ok $list->[2] == $ld30;
  };
  
  subtest 'array return' => sub {
    plan tests => 3;
    my $list = longdouble_array_return_test();
    note "[", join(',', map { "$_" } @$list), "]";
    ok $list->[0] == $ld10;
    ok $list->[1] == $ld20;
    ok $list->[2] == $ld30;
  };
};

subtest 'without Math::LongDouble' => sub {
  plan tests => 5;

  if(FFI::Platypus::_have_math_longdouble())
  {
    note "You have Math::LongDouble, but for this test we are going to turn it off";
    FFI::Platypus::_have_math_longdouble(0);
  }

  subtest 'scalar' => sub {
    plan tests => 1;
    is add(1.5, 2.5), 4.0, "add(1.5,2.5) = 4";
  };

  subtest 'pointer' => sub {
    plan tests => 5;
    my $a = 1.5;
    my $b = 2.5;
    ok longdouble_pointer_test(\$a, \$b);
    ok $a == 4.0;
    ok $b == 8.0;
    ok pointer_is_null(undef);
    
    my $c = longdouble_pointer_return_test(1.5);
    ok $$c == 1.5;
  };

  subtest 'array fixed' => sub {
    plan tests => 4;
    my $list = [ qw( 25.0 25.0 50.0 )];
    
    ok longdouble_array_test3($list, 3);
    note "[", join(',', map { "$_" } @$list), "]";
    ok $list->[0] == 1.0;
    ok $list->[1] == 2.0;
    ok $list->[2] == 3.0;
  };

  subtest 'array var' => sub {
    plan tests => 4;
    my $list = [ qw( 25.0 25.0 50.0 )];
    
    ok longdouble_array_test($list, 3);
    note "[", join(',', map { "$_" } @$list), "]";
    ok $list->[0] == 1.0;
    ok $list->[1] == 2.0;
    ok $list->[2] == 3.0;
  };

  subtest 'array return' => sub {
    plan tests => 3;
    my $list = longdouble_array_return_test();
    note "[", join(',', map { "$_" } @$list), "]";
    ok $list->[0] == 1.0;
    ok $list->[1] == 2.0;
    ok $list->[2] == 3.0;
  };
};
