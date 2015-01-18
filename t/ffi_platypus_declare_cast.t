use strict;
use warnings;
use Test::More tests => 3;
use FFI::Platypus::Declare;
use FFI::CheckLib;

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

attach string_matches_foobarbaz => ['opaque'] => 'int';
attach string_return_foobarbaz  => [] => 'opaque';
attach string_set_closure => ['opaque'] => 'void';
attach string_call_closure => ['string'] => 'void';

subtest 'cast from string to pointer' => sub {
  plan tests => 2;

  my $string = "foobarbaz";
  my $pointer = cast string => opaque => $string;
  
  is string_matches_foobarbaz($pointer), 1, 'dynamic';

  attach_cast cast1 => string => 'opaque';
  my $pointer2 = cast1($string);
  
  is string_matches_foobarbaz($pointer2), 1, 'static';

};

subtest 'cast from pointer to string' => sub {
  plan tests => 2;

  my $pointer = string_return_foobarbaz();
  my $string = cast opaque => string => $pointer;
  
  is $string, "foobarbaz", "dynamic";
  
  attach_cast cast2 => pointer => 'string';
  my $string2 = cast2($pointer);

  is $string2, "foobarbaz", "static";

};

subtest 'cast closure to opaque' => sub {
  plan tests => 2;

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
