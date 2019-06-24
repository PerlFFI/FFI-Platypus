use strict;
use warnings;
use Test::More;
use FFI::Platypus::Function;
use FFI::Platypus;
use FFI::CheckLib;

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

subtest 'built in type' => sub {
  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);
  my $wrapper  = sub {
    my($xsub, $arg1) = @_;
    $xsub->( $arg1 * 2 );
  };
  my $function = eval { $ffi->function('f0', [ 'uint8' ] => 'uint8', $wrapper ) };
  is $@, '', 'ffi.function(f0, [uint8] => uint8)';
  isa_ok $function, 'FFI::Platypus::Function';
  isa_ok $function, 'FFI::Platypus::Function::Wrapper';
  is $function->call(22), 44, 'function.call(22) = 44';
  is $function->(22), 44, 'function.(22) = 44';

  $function->attach('baboon');
  is( baboon(11), 22, "baboon(11) = 22" );
};

subtest 'sub_ref' => sub {

  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);
  my $sub_ref = $ffi->function('f0', [ 'uint8' ] => 'uint8', sub { my($xsub, $arg) = @_; $arg*2})->sub_ref;

  is $sub_ref->(99), 99*2, 'calls okay';
  is ref($sub_ref), 'CODE', 'it is a code reference';

  if(eval { require Sub::Identify; 1 })
  {
    my $name = Sub::Identify::sub_name($sub_ref);
    my $package = Sub::Identify::stash_name($sub_ref);
    note "name = ${package}::$name";
  }
};

subtest 'prototype' => sub {

  subtest one => sub {

    my $ffi = FFI::Platypus->new;
    $ffi->lib($libtest);
    my $sub_ref = $ffi->attach(['f0' => 'f0_prototyped1'], [ 'uint8' ] => 'uint8', '$', sub { my($xsub, $arg) = @_; $arg*2});

    is(f0_prototyped1(2), 4); # just make sure it attached okay
    is(prototype(\&f0_prototyped1), '$');

  };

  subtest two => sub {

    my $ffi = FFI::Platypus->new;
    $ffi->lib($libtest);
    my $sub_ref = $ffi->function('f0', [ 'uint8' ] => 'uint8', sub { my($xsub, $arg) = @_; $arg*2})->attach('f0_prototyped2', '$');

    is(f0_prototyped2(2), 4); # just make sure it attached okay
    is(prototype(\&f0_prototyped2), '$');

  };

};

done_testing;
