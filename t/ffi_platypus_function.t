use strict;
use warnings;
use Test::More;
use FFI::Platypus::Function;
use FFI::Platypus;
use FFI::CheckLib;
use FFI::Platypus::TypeParser::Version0;

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

subtest 'built in type' => sub {
  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);
  my $function = eval { $ffi->function('f0', [ 'uint8' ] => 'uint8') };
  is $@, '', 'ffi.function(f0, [uint8] => uint8)';
  isa_ok $function, 'FFI::Platypus::Function';
  isa_ok $function, 'FFI::Platypus::Function::Function';
  is $function->call(22), 22, 'function.call(22) = 22';
  is $function->(22), 22, 'function.(22) = 22';
};

subtest 'custom type' => sub {
  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);
  $ffi->type('uint8' => 'my_int_8');
  my $function = eval { $ffi->function('f0', [ 'my_int_8' ] => 'my_int_8') };
  is $@, '', 'ffi.function(f0, [my_int_8] => my_int_8)';
  isa_ok $function, 'FFI::Platypus::Function';
  isa_ok $function, 'FFI::Platypus::Function::Function';
  is $function->call(22), 22, 'function.call(22) = 22';
  is $function->(22), 22, 'function.(22) = 22';
};

subtest 'private' => sub {
  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);

  my $address = $ffi->find_symbol('f0');
  my $uint8   = FFI::Platypus::TypeParser::Version0->new->parse('uint8');

  my $function = eval { FFI::Platypus::Function::Function->new($ffi, $address, -1, -1, $uint8, $uint8) };
  is $@, '', 'FFI::Platypus::Function->new';
  isa_ok $function, 'FFI::Platypus::Function';
  isa_ok $function, 'FFI::Platypus::Function::Function';

  is $function->call(22), 22, 'function.call(22) = 22';

  $function->attach('main::fooble', 'whatever.c', undef);

  is fooble(22), 22, 'fooble(22) = 22';

};

subtest 'meta' => sub {
  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);

  $ffi->attach(mymeta_new    => [ 'int', 'string' ] => 'opaque');
  $ffi->attach(mymeta_delete => [ 'opaque' ] => 'void' );

  subtest 'unattached' => sub {

    my $meta = mymeta_new(4, "prime");

    my $f = $ffi->_function_meta('mymeta_test' => $meta => [ 'string' ] => 'string' );

    is($f->call(), "foo = 4, bar = prime, baz = undef, count = 0");
    is($f->call("just one"), "foo = 4, bar = prime, baz = just one, count = 1");

    mymeta_delete($meta);

  };

  subtest 'attached' => sub {

    my $meta = mymeta_new(6, "magnus");

    $ffi->_function_meta('mymeta_test' => $meta => [ 'string' ] => 'string' )->attach('mymeta_test1');

    is(mymeta_test1(), "foo = 6, bar = magnus, baz = undef, count = 0");
    is(mymeta_test1("stella"), "foo = 6, bar = magnus, baz = stella, count = 1");
  };

};

subtest 'sub_ref' => sub {

  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);
  my $sub_ref = $ffi->function('f0', [ 'uint8' ] => 'uint8')->sub_ref;

  is $sub_ref->(99), 99, 'calls okay';
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
    my $sub_ref = $ffi->attach(['f0' => 'f0_prototyped1'], [ 'uint8' ] => 'uint8', '$');

    is(f0_prototyped1(2), 2); # just make sure it attached okay
    is(prototype(\&f0_prototyped1), '$');

  };

  subtest two => sub {

    my $ffi = FFI::Platypus->new;
    $ffi->lib($libtest);
    my $sub_ref = $ffi->function('f0', [ 'uint8' ] => 'uint8')->attach('f0_prototyped2', '$');

    is(f0_prototyped2(2), 2); # just make sure it attached okay
    is(prototype(\&f0_prototyped2), '$');

  };

};

subtest 'variadic' => sub {

  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);

  plan skip_all => 'test requires variadic function support'
    unless eval { $ffi->function('variadic_return_arg' => ['int'] => ['int'] => 'int') };


  my $wrapper = sub {
    my($xsub, @args) = @_;
    my $ret = $xsub->(@args);
    $ret*2;
  };

  subtest 'unattached' => sub {

    is(
      $ffi->function(variadic_return_arg => ['int'] => ['int','int','int','int','int','int','int'] => 'int')->call(4,10,20,30,40,50,60,70),
      40,
      'sans wrapper'
    );

    is(
      $ffi->function(variadic_return_arg => ['int'] => ['int','int','int','int','int','int','int'] => 'int', $wrapper)->call(4,10,20,30,40,50,60,70),
      80,
      'with wrapper'
    );
  };

  subtest 'attached' => sub {

    $ffi->attach([variadic_return_arg => 'y1'] => ['int'] => ['int','int','int','int','int','int','int'] => 'int');
    is(y1(4,10,20,30,40,50,60,70), 40, 'sans wrapper');

    $ffi->attach([variadic_return_arg => 'y2'] => ['int'] => ['int','int','int','int','int','int','int'] => 'int', $wrapper);
    is(y2(4,10,20,30,40,50,60,70), 80, 'with wrapper');

  };

};

subtest 'void as arg should fail is arg count > 1' => sub {

  my $ffi = FFI::Platypus->new;

  eval { $ffi->function( 0 => ['int','void'] => 'void' ) };
  like "$@", qr/^void not allowed as argument type/;

};

done_testing;

