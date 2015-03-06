use strict;
use warnings;
use Test::More tests => 3;
use FFI::Platypus;
use FFI::CheckLib;

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 'libtest');

subtest 'cast from string to pointer' => sub {
  plan tests => 2;

  my $string = "foobarbaz";
  my $pointer = $ffi->cast(string => opaque => $string);
  
  is $ffi->function(string_matches_foobarbaz => ['opaque'] => 'int')->call($pointer), 1, 'dynamic';

  $ffi->attach_cast(cast1 => string => 'opaque');
  my $pointer2 = cast1($string);
  
  is $ffi->function(string_matches_foobarbaz => ['opaque'] => 'int')->call($pointer2), 1, 'static';

};

subtest 'cast from pointer to string' => sub {
  plan tests => 2;

  my $pointer = $ffi->function(string_return_foobarbaz => [] => 'opaque')->call();
  my $string = $ffi->cast(opaque => string => $pointer);
  
  is $string, "foobarbaz", "dynamic";
  
  $ffi->attach_cast(cast2 => pointer => 'string');
  my $string2 = cast2($pointer);

  is $string2, "foobarbaz", "static";

};

subtest 'cast closure to opaque' => sub {
  plan tests => 4;

  my $testname = 'dynamic';

  my $closure = $ffi->closure(sub { is $_[0], "testvalue", $testname });
  my $pointer = $ffi->cast('(string)->void' => opaque => $closure);
  
  $ffi->function(string_set_closure => ['opaque'] => 'void')->call($pointer);
  $ffi->function(string_call_closure => ['string'] => 'void')->call("testvalue");

  $ffi->function(string_set_closure => ['(string)->void'] => 'void')->call($pointer);
  $ffi->function(string_call_closure => ['string'] => 'void')->call("testvalue");

  $ffi->attach_cast('cast3', '(string)->void' => 'opaque');
  my $pointer2 = cast3($closure);

  $testname = 'static';
  $ffi->function(string_set_closure => ['opaque'] => 'void')->call($pointer2);
  $ffi->function(string_call_closure => ['string'] => 'void')->call("testvalue");

  $ffi->function(string_set_closure => ['(string)->void'] => 'void')->call($pointer2);
  $ffi->function(string_call_closure => ['string'] => 'void')->call("testvalue");
};
