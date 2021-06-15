#
# DO NOT MODIFY THIS FILE.
# This file generated from similar file t/type_sint8.t
# all instances of "int8" have been changed to "int16"
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
    $ffi->type('sint16 *' => 'sint16_p');
    $ffi->type('sint16 [10]' => 'sint16_a');
    $ffi->type('sint16 []' => 'sint16_a2');
    $ffi->type('(sint16)->sint16' => 'sint16_c');

    $ffi->attach( [sint16_add => 'add'] => ['sint16', 'sint16'] => 'sint16');
    $ffi->attach( [sint16_inc => 'inc'] => ['sint16_p', 'sint16'] => 'sint16_p');
    $ffi->attach( [sint16_sum => 'sum'] => ['sint16_a'] => 'sint16');
    $ffi->attach( [sint16_sum2 => 'sum2'] => ['sint16_a2','size_t'] => 'sint16');
    $ffi->attach( [sint16_array_inc => 'array_inc'] => ['sint16_a'] => 'void');
    $ffi->attach( [pointer_null => 'null'] => [] => 'sint16_p');
    $ffi->attach( [pointer_is_null => 'is_null'] => ['sint16_p'] => 'int');
    $ffi->attach( [sint16_static_array => 'static_array'] => [] => 'sint16_a');
    $ffi->attach( [pointer_null => 'null2'] => [] => 'sint16_a');

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
    $ffi->attach( [sint16_set_closure => 'set_closure'] => ['sint16_c'] => 'void');
    $ffi->attach( [sint16_call_closure => 'call_closure'] => ['sint16'] => 'sint16');

    set_closure($closure);
    is call_closure(-2), -4, 'call_closure(-2) = -4';

    $closure = $ffi->closure(sub { undef });
    set_closure($closure);
    is do { no warnings; call_closure(2) }, 0, 'call_closure(2) = 0';

    subtest 'custom type input' => sub {
      $ffi->custom_type(type1 => { native_type => 'uint16', perl_to_native => sub { is $_[0], -2; $_[0]*2 } });
      $ffi->attach( [sint16_add => 'custom_add'] => ['type1','sint16'] => 'sint16');
      is custom_add(-2,-1), -5, 'custom_add(-2,-1) = -5';
    };

    subtest 'custom type output' => sub {
      $ffi->custom_type(type2 => { native_type => 'sint16', native_to_perl => sub { is $_[0], -3; $_[0]*2 } });
      $ffi->attach( [sint16_add => 'custom_add2'] => ['sint16','sint16'] => 'type2');
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
    $ffi->type('object(Roger,sint16)', 'roger_t');

    my $int = -22;

    subtest 'argument' => sub {

      is $ffi->cast('roger_t' => 'sint16', bless(\$int, 'Roger')), $int;

    };

    subtest 'return value' => sub {

      my $obj1 = $ffi->cast('sint16' => 'roger_t', $int);
      isa_ok $obj1, 'Roger';
      is $$obj1, $int;
    };

  };

};

done_testing;
