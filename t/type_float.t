use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::CheckLib;

my @lib = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

foreach my $api (0, 1, 2)
{

  subtest "api = $api" => sub {

    local $SIG{__WARN__} = sub {
      my $message = shift;
      return if $message =~ /^Subroutine main::.* redefined/;
      warn $message;
    };

    my $ffi = FFI::Platypus->new( api => $api, lib => [@lib], experimental => ($api > 2 ? $api : undef) );
    $ffi->type('float *' => 'float_p');
    $ffi->type('float [10]' => 'float_a');
    $ffi->type('float []' => 'float_a2');
    $ffi->type('(float)->float' => 'float_c');

    $ffi->attach( [float_add => 'add'] => ['float', 'float'] => 'float');
    $ffi->attach( [float_inc => 'inc'] => ['float_p', 'float'] => 'float_p');
    $ffi->attach( [float_sum => 'sum'] => ['float_a'] => 'float');
    $ffi->attach( [float_sum2 => 'sum2'] => ['float_a2','size_t'] => 'float');
    $ffi->attach( [float_array_inc => 'array_inc'] => ['float_a'] => 'void');
    $ffi->attach( [pointer_null => 'null'] => [] => 'float_p');
    $ffi->attach( [pointer_is_null => 'is_null'] => ['float_p'] => 'int');
    $ffi->attach( [float_static_array => 'static_array'] => [] => 'float_a');
    $ffi->attach( [pointer_null => 'null2'] => [] => 'float_a');

    if($api >= 2)
    {
      $ffi->attach( [float_sum => 'sum3'] => ['float*'] => 'float');
      $ffi->attach( [float_array_inc => 'array_inc2'] => ['float*'] => 'void');
    }

    is add(1.5,2.5), 4, 'add(1.5,2.5) = 4';
    is eval { no warnings; add() }, 0.0, 'add() = 0.0';

    my $i = 3.5;
    is ${inc(\$i, 4.25)}, 7.75, 'inc(\$i,4.25) = \7.75';

    is $i, 3.5+4.25, "i=3.5+4.25";

    is ${inc(\3,4)}, 7, 'inc(\3,4) = \7';

    my @list = (1,2,3,4,5,6,7,8,9,10);

    is sum(\@list), 55, 'sum([1..10]) = 55';
    is sum2(\@list,scalar @list), 55, 'sum2([1..10],10) = 55';

    if($api >= 2)
    {
      is sum3(\@list), 55, 'sum([1..10]) = 55';
    }

    array_inc(\@list);
    do { local $SIG{__WARN__} = sub {}; array_inc(); };

    is \@list, [2,3,4,5,6,7,8,9,10,11], 'array increment';

    if($api >= 2)
    {
      array_inc2(\@list);
      is \@list, [3,4,5,6,7,8,9,10,11,12], 'array increment';
    }

    is [null()], [$api >= 2 ? (undef) : ()], 'null() == undef';
    is is_null(undef), 1, 'is_null(undef) == 1';
    is is_null(), 1, 'is_null() == 1';
    is is_null(\22), 0, 'is_null(22) == 0';

    is static_array(), [-5.5, 5.5, -10, 10, -15.5, 15.5, 20, -20, 25.5, -25.5], 'static_array = [-5.5, 5.5, -10, 10, -15.5, 15.5, 20, -20, 25.5, -25.5]';

    is [null2()], [$api >= 2 ? (undef) : ()], 'null2() == undef';

    my $closure = $ffi->closure(sub { $_[0]+2.25 });
    $ffi->attach( [float_set_closure => 'set_closure'] => ['float_c'] => 'void');
    $ffi->attach( [float_call_closure => 'call_closure'] => ['float'] => 'float');

    set_closure($closure);
    is call_closure(2.5), 4.75, 'call_closure(2.5) = 4.75';

    $closure = $ffi->closure(sub { undef });
    set_closure($closure);
    is do { no warnings; call_closure(2.5) }, 0, 'call_closure(2.5) = 0';

    subtest 'custom type input' => sub {
      $ffi->custom_type(type1 => { native_type => 'float', perl_to_native => sub { is $_[0], 1.25; $_[0]+0.25 } });
      $ffi->attach( [float_add => 'custom_add'] => ['type1','float'] => 'float');
      is custom_add(1.25,2.5), 4, 'custom_add(1.25,2.5) = 4';
    };

    subtest 'custom type output' => sub {
      $ffi->custom_type(type2 => { native_type => 'float', native_to_perl => sub { is $_[0], 2.0; $_[0]+0.25 } });
      $ffi->attach( [float_add => 'custom_add2'] => ['float','float'] => 'type2');
      is custom_add2(1,1), 2.25, 'custom_add2(1,1) = 2.25';
    };

    $ffi->attach( [pointer_is_null => 'closure_pointer_is_null'] => ['()->void'] => 'int');
    is closure_pointer_is_null(), 1, 'closure_pointer_is_null() = 1';
  };
}

done_testing;
