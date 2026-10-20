use Test2::V0 -no_srand => 1;
use Cwd qw( abs_path );
BEGIN { skip_all 'Test requires a threading Perl' unless eval q{ use threads; 1 } }
use FFI::CheckLib;
use FFI::Platypus;
use FFI::Platypus::Closure;
use Config;

my $ffi = FFI::Platypus->new(lib => find_lib(lib => 'test', symbol => 'f0', libpath => abs_path('t/ffi') ));

sub f0
{
  $ffi->function(f0 => ['uint8'] => 'uint8')->call(@_);
}

sub otherthread
{
  my $val = f0(22);
  undef $ffi;
  $val;
}

ok 1;

is(threads->create(\&otherthread)->join(), 22, 'works in a thread');

is f0(24), 24, 'works in main thread';

subtest 'closure used in parent and child thread' => sub {
  my $lib = find_lib(lib => 'test', symbol => 'f0', libpath => abs_path('t/ffi'));
  my $closure = FFI::Platypus::Closure->new(sub { $_[0] * 2 });

  # use a fresh Platypus instance for each call, so that no type or function
  # objects exist when the thread is created; only the closure is cloned.
  my $call = sub {
    my $ffi = FFI::Platypus->new( api => 2, lib => $lib );
    $ffi->function( closure_call_closure_immediate => ['(int)->int', 'int'] => 'int' )->call($closure, $_[0]);
  };

  is $call->(1), 2, 'parent before';

  # the child must not free the parent's C closure when it exits
  # (if it does, we crash during global destruction)
  is(threads->create(sub { $call->(2) })->join, 4, 'child');

  is $call->(3), 6, 'parent after';
};

done_testing;
