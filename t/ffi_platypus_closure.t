use strict;
use warnings;
use Test::More;
use FFI::Platypus::Closure;
use FFI::CheckLib;

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

subtest 'basic' => sub {
  my $ffi = FFI::Platypus->new;

  my $closure = $ffi->closure(sub { $_[0] + 1});
  isa_ok $closure, 'FFI::Platypus::Closure';
  is $closure->(1), 2, 'closure.(1) = 2';

  my $c = sub { $_[0] + 2 };
  $closure = $ffi->closure($c);
  isa_ok $closure, 'FFI::Platypus::Closure';
  is $closure->(1), 3, 'closure.(1) = 3';
  is $closure->call(1), 3, 'closure.call(1) = 3';

  $closure = $ffi->closure($c);
  isa_ok $closure, 'FFI::Platypus::Closure';
  is $closure->(1), 3, 'closure.(1) = 3';
  is $closure->call(1), 3, 'closure.call(1) = 3';
};

subtest 'sticky' => sub {
  my $closure = FFI::Platypus::Closure->new(sub { 'foo' });
  isa_ok $closure, 'FFI::Platypus::Closure';

  my $refcnt = $closure->_svrefcnt;
  note "_svrefcnt = $refcnt";

  eval { $closure->sticky };
  is $@, '', 'called $closure->sticky';

  is($closure->_svrefcnt, $refcnt+2);

  eval { $closure->sticky };
  is $@, '', 'called $closure->sticky';

  is($closure->_svrefcnt, $refcnt+2);

  eval { $closure->unstick };
  is $@, '', 'called $closure->unstick';

  is($closure->_svrefcnt, $refcnt);
};

subtest 'private' => sub {
  my $closure = FFI::Platypus::Closure->new(sub { $_[0] + 1});
  isa_ok $closure, 'FFI::Platypus::Closure';
  is $closure->(1), 2, 'closure.(1) = 2';
};

subtest 'space' => sub {
  my $ffi = FFI::Platypus->new;

  eval { $ffi->type('(int,int)->void') };
  is $@, '', 'good without space';

  eval { $ffi->type('(int, int) -> void') };
  is $@, '', 'good with space';
};

subtest 'die' => sub {
  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);

  my $closure = $ffi->closure(sub {
    die "omg i don't want to die!";
  });

  my $set_closure = $ffi->function(pointer_set_closure => ['(opaque)->opaque'] => 'void');
  my $call_closure = $ffi->function(pointer_call_closure => ['opaque'] => 'opaque');

  $set_closure->($closure);

  my $warning;
  do {
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    $call_closure->(undef);
  };

  like $warning, qr{omg i don't want to die};
  pass 'does not exit';
  note "warning = '$warning'";
};

subtest 'reuse' => sub {
  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);

  my $closure = $ffi->closure(sub {
    if (@_) {
      return $_[0] * 7;
    }
    return 21;
  });

  my $set_closure1 = $ffi->function( closure_set_closure1 => ['()->int'] => 'void');
  my $set_closure2 = $ffi->function( closure_set_closure2 => ['(int)->int'] => 'void');
  my $call_closure1 = $ffi->function( closure_call_closure1 => [] => 'int');
  my $call_closure2 = $ffi->function( closure_call_closure2 => ['int'] => 'int');

  $set_closure1->($closure);
  $set_closure2->($closure);

  is $call_closure1->(), 21;
  is $call_closure2->(42), 294;
};

subtest 'immediate' => sub {
  my $ffi = FFI::Platypus->new;
  $ffi->lib($libtest);

  my $ret = $ffi->function( closure_call_closure_immediate => ['()->int'] => 'int')->call(
    $ffi->closure(sub { return 42; })
  );

  is $ret, 42;
};

subtest 'closure passing into a closure' => sub {

  my $ffi = FFI::Platypus->new;
  eval { $ffi->type('((int)->int)->int') };
  isnt "$@", "";
  note "error = $@";

  $ffi->type('(int)->int' => 'foo_t');
  eval { $ffi->type('()->foo_t') };
  isnt "$@", "";
  note "error = $@";

};

done_testing;
