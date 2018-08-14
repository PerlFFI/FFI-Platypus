use strict;
use warnings;
use Test::More;
use FFI::CheckLib;
use FFI::Platypus::Declare;

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

subtest normal => sub {

  { package Normal;

    use FFI::Platypus::Declare;

    lib $libtest;
    attach 'f0', ['uint8'] => 'uint8';
    attach [f0 => 'f1'], ['uint8'] => 'uint8';

    attach [f0 => 'f0_wrap'] => ['uint8'] => 'uint8' => sub {
      my($inner, $value) = @_;
      $inner->($value+1)+2;
    };

    attach [f0 => 'f0_wrap2'] => ['uint8'] => 'uint8' => '$' => sub {
      my($inner, $value) = @_;
      $inner->($value+1)+2;
    };
  }

  is Normal::f0(22), 22, 'f0(22) = 22';
  is Normal::f1(22), 22, 'f1(22) = 22';
  is Normal::f0_wrap(22), 25, 'f0_wrap(22) = 25';
  is Normal::f0_wrap2(22), 25, 'f0_wrap2(22) = 25';
};

subtest 'with type aliases' => sub {

  { package WithTypeAliases;

    use FFI::Platypus::Declare
      'string',
      [int => 'myint'];

    lib $libtest;
    attach [my_atoi=>'atoi'], [string] => myint;
  }

  is WithTypeAliases::atoi("42"), 42, 'atoi("42") = 42';
};

subtest 'simple closure test' => sub {

  { package ClosureSimple;

    use FFI::Platypus::Declare;

    our $closure = closure { $_[0]+1 };
  }

  isa_ok $ClosureSimple::closure, 'FFI::Platypus::Closure';
  is $ClosureSimple::closure->(1), 2, 'closure.(1) = 2';
};

subtest 'abis' => sub {

  my %abis = %{ FFI::Platypus->abis };

  ok defined $abis{default_abi}, 'has a default ABI';

  foreach my $abi (keys %abis)
  {
    subtest $abi => sub {
      eval { abi $abi };
      is $@, '', 'string';
      eval { abi $abis{$abi} };
      is $@, '', 'integer';
    };
  }

  subtest 'bogus' => sub {
    eval { abi 'bogus' };
    like $@, qr{no such ABI: bogus}, 'string';
    eval { abi 999999 };
    like $@, qr{no such ABI: 999999}, 'integer';
  };
};

subtest 'lang' => sub {

  subtest C => sub {

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

    package
      FFI::Platypus::Lang::Foo;

    sub native_type_map
    {
      {
        foo_t => 'sint16',
        bar_t => 'uint32',
      }
    }

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
};

subtest 'sizeof' => sub {
  is sizeof 'uint32', 4, 'sizeof uint32 = 4';
  is sizeof 'uint32[2]', 8, 'sizeof uint32[2] = 8';
};

subtest 'sticky' => sub {
  package Foo;

  use Test::More;
  use FFI::Platypus::Declare
    qw( uint8 void ),
    ['(uint8)->uint8' => 'closure_t'];

  lib $libtest;

  attach [uint8_set_closure => 'set_closure']   => [closure_t] => void;
  attach [uint8_call_closure => 'call_closure'] => [uint8] => uint8;

  set_closure(sticky closure { $_[0] * 2 });
  is call_closure(2), 4, 'call_closure(2) = 4';
};

subtest 'cast' => sub {
  package Bar;

  use Test::More;
  use FFI::Platypus::Declare;

  lib $libtest;

  attach string_matches_foobarbaz => ['opaque'] => 'int';
  attach string_return_foobarbaz  => [] => 'opaque';
  attach string_set_closure => ['opaque'] => 'void';
  attach string_call_closure => ['string'] => 'void';

  subtest 'cast from string to pointer' => sub {
    my $string = "foobarbaz";
    my $pointer = cast string => opaque => $string;

    is string_matches_foobarbaz($pointer), 1, 'dynamic';

    attach_cast cast1 => string => 'opaque';
    my $pointer2 = cast1($string);

    is string_matches_foobarbaz($pointer2), 1, 'static';

  };

  subtest 'cast from pointer to string' => sub {
    my $pointer = string_return_foobarbaz();
    my $string = cast opaque => string => $pointer;

    is $string, "foobarbaz", "dynamic";

    attach_cast cast2 => pointer => 'string';
    my $string2 = cast2($pointer);

    is $string2, "foobarbaz", "static";

  };

  subtest 'cast closure to opaque' => sub {
    my $testname = 'dynamic';

    my $closure = closure { is $_[0], "testvalue", $testname };
    my $pointer = cast '(string)->void' => opaque => $closure;

    string_set_closure($pointer);
    string_call_closure("testvalue");

    attach_cast 'cast3', '(string)->void' => 'opaque';
    my $pointer2 = cast3($closure);

    $testname = 'static';
    string_set_closure($pointer2);
    string_call_closure("testvalue");
  };
};

done_testing;
