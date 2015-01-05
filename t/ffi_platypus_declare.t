use strict;
use warnings;
use Test::More tests => 2;

do {
  package
    Normal;

  use FFI::CheckLib;
  use FFI::Platypus::Declare;

  lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';
  function 'f0', ['uint8'] => 'uint8';
  function [f0 => 'f1'], ['uint8'] => 'uint8';
};

subtest normal => sub {
  plan tests => 2;
  is Normal::f0(22), 22, 'f0(22) = 22';
  is Normal::f1(22), 22, 'f1(22) = 22';
};

do {
  package
    WithTypeAliases;
    
  use FFI::CheckLib;
  use FFI::Platypus::Declare
    'string',
    [int => 'myint'];
  
  lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';
  function [my_atoi=>'atoi'], [string] => myint;
  
  
};

subtest 'with type aliases' => sub {
  plan tests => 1;
  is WithTypeAliases::atoi("42"), 42, 'atoi("42") = 42';
};
