#
# DO NOT MODIFY THIS FILE.
# This file generated from similar file t/type_sint8.t
# all instances of "int8" have been changed to "int32"
#
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

    my $ffi = FFI::Platypus->new( api => $api, lib => [@lib], experimental => ($api >=2 ? $api : undef) );
    $ffi->type('sint32 *' => 'sint32_p');
    $ffi->type('sint32 [10]' => 'sint32_a');
    $ffi->type('sint32 []' => 'sint32_a2');
    $ffi->type('(sint32)->sint32' => 'sint32_c');

    $ffi->attach( [sint32_add => 'add'] => ['sint32', 'sint32'] => 'sint32');
    $ffi->attach( [sint32_inc => 'inc'] => ['sint32_p', 'sint32'] => 'sint32_p');
    $ffi->attach( [sint32_sum => 'sum'] => ['sint32_a'] => 'sint32');
    $ffi->attach( [sint32_sum2 => 'sum2'] => ['sint32_a2','size_t'] => 'sint32');
    $ffi->attach( [sint32_array_inc => 'array_inc'] => ['sint32_a'] => 'void');
    $ffi->attach( [pointer_null => 'null'] => [] => 'sint32_p');
    $ffi->attach( [pointer_is_null => 'is_null'] => ['sint32_p'] => 'int');
    $ffi->attach( [sint32_static_array => 'static_array'] => [] => 'sint32_a');
    $ffi->attach( [pointer_null => 'null2'] => [] => 'sint32_a');

    is add(-1,2), 1, 'add(-1,2) = 1';
    is do { no warnings; add() }, 0, 'add() = 0';

    my $i = -3;
    is ${inc(\$i, 4)}, 1, 'inc(\$i,4) = \1';

    is $i, 1, "i=1";

    is ${inc(\-3,4)}, 1, 'inc(\-3,4) = \1';

    my @list = (-5,-4,-3,-2,-1,0,1,2,3,4);

    is sum(\@list), -5, 'sum([-5..4]) = -5';
    is sum2(\@list,scalar @list), -5, 'sum([-5..4],10) = -5';

    array_inc(\@list);
    do { local $SIG{__WARN__} = sub {}; array_inc() };

    is \@list, [-4,-3,-2,-1,0,1,2,3,4,5], 'array increment';

    is [null()], [$api >= 2 ? (undef) : ()], 'null() == undef';
    is is_null(undef), 1, 'is_null(undef) == 1';
    is is_null(), 1, 'is_null() == 1';
    is is_null(\22), 0, 'is_null(22) == 0';

    is static_array(), [-1,2,-3,4,-5,6,-7,8,-9,10], 'static_array = [-1,2,-3,4,-5,6,-7,8,-9,10]';

    is [null2()], [$api >= 2 ? (undef) : ()], 'null2() == undef';

    my $closure = $ffi->closure(sub { $_[0]-2 });
    $ffi->attach( [sint32_set_closure => 'set_closure'] => ['sint32_c'] => 'void');
    $ffi->attach( [sint32_call_closure => 'call_closure'] => ['sint32'] => 'sint32');

    set_closure($closure);
    is call_closure(-2), -4, 'call_closure(-2) = -4';

    $closure = $ffi->closure(sub { undef });
    set_closure($closure);
    is do { no warnings; call_closure(2) }, 0, 'call_closure(2) = 0';

    subtest 'custom type input' => sub {
      $ffi->custom_type(type1 => { native_type => 'uint32', perl_to_native => sub { is $_[0], -2; $_[0]*2 } });
      $ffi->attach( [sint32_add => 'custom_add'] => ['type1','sint32'] => 'sint32');
      is custom_add(-2,-1), -5, 'custom_add(-2,-1) = -5';
    };

    subtest 'custom type output' => sub {
      $ffi->custom_type(type2 => { native_type => 'sint32', native_to_perl => sub { is $_[0], -3; $_[0]*2 } });
      $ffi->attach( [sint32_add => 'custom_add2'] => ['sint32','sint32'] => 'type2');
      is custom_add2(-2,-1), -6, 'custom_add2(-2,-1) = -6';
    };

    $ffi->attach( [pointer_is_null => 'closure_pointer_is_null'] => ['()->void'] => 'int');
    is closure_pointer_is_null(), 1, 'closure_pointer_is_null() = 1';
  };
}

foreach my $api (1,2)
{
  subtest 'object' => sub {

    { package Roger }

    my $ffi = FFI::Platypus->new( api => $api, lib => [@lib], experimental => ($api >=2 ? $api : undef) );
    $ffi->type('object(Roger,sint32)', 'roger_t');

    my $int = -22;

    subtest 'argument' => sub {

      is $ffi->cast('roger_t' => 'sint32', bless(\$int, 'Roger')), $int;

    };

    subtest 'return value' => sub {

      my $obj1 = $ffi->cast('sint32' => 'roger_t', $int);
      isa_ok $obj1, 'Roger';
      is $$obj1, $int;
    };

  };

};

done_testing;
