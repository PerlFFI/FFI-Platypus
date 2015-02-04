use strict;
use warnings;
use Test::More tests => 3;

do {
  package
    Normal;

  use FFI::CheckLib;
  use FFI::Platypus::Declare;

  lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';
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
};

subtest normal => sub {
  plan tests => 4;
  is Normal::f0(22), 22, 'f0(22) = 22';
  is Normal::f1(22), 22, 'f1(22) = 22';
  is Normal::f0_wrap(22), 25, 'f0_wrap(22) = 25';
  is Normal::f0_wrap2(22), 25, 'f0_wrap2(22) = 25';
};

do {
  package
    WithTypeAliases;
    
  use FFI::CheckLib;
  use FFI::Platypus::Declare
    'string',
    [int => 'myint'];
  
  lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';
  attach [my_atoi=>'atoi'], [string] => myint;
  
  
};

subtest 'with type aliases' => sub {
  plan tests => 1;
  is WithTypeAliases::atoi("42"), 42, 'atoi("42") = 42';
};

do {
  package
    ClosureSimple;
  
  use FFI::Platypus::Declare;
  
  our $closure = closure { $_[0]+1 };
};

subtest 'simple closure test' => sub {
  plan tests => 2;
  isa_ok $ClosureSimple::closure, 'FFI::Platypus::Closure';
  is $ClosureSimple::closure->(1), 2, 'closure.(1) = 2';
};
