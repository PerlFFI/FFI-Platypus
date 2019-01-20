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
  my $uint8   = FFI::Platypus::Type->new('uint8');

  my $function = eval { FFI::Platypus::Function::Function->new($ffi, $address, -1, $uint8, $uint8) };
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

done_testing;
