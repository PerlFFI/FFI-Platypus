#
# DO NOT MODIFY THIS FILE.
# This file generated from similar file t/type_uint8.t
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

    my $ffi = FFI::Platypus->new( api => $api, lib => [@lib], experimental => ($api > 2 ? $api : undef ) );
    $ffi->type('uint32 *' => 'uint32_p');
    $ffi->type('uint32 [10]' => 'uint32_a');
    $ffi->type('uint32 []' => 'uint32_a2');
    $ffi->type('(uint32)->uint32' => 'uint32_c');

    $ffi->attach( [uint32_add => 'add'] => ['uint32', 'uint32'] => 'uint32');
    $ffi->attach( [uint32_inc => 'inc'] => ['uint32_p', 'uint32'] => 'uint32_p');
    $ffi->attach( [uint32_sum => 'sum'] => ['uint32_a'] => 'uint32');
    $ffi->attach( [uint32_sum2 => 'sum2'] => ['uint32_a2','size_t'] => 'uint32');
    $ffi->attach( [uint32_array_inc => 'array_inc'] => ['uint32_a'] => 'void');
    $ffi->attach( [pointer_null => 'null'] => [] => 'uint32_p');
    $ffi->attach( [pointer_is_null => 'is_null'] => ['uint32_p'] => 'int');
    $ffi->attach( [uint32_static_array => 'static_array'] => [] => 'uint32_a');
    $ffi->attach( [pointer_null => 'null2'] => [] => 'uint32_a');

    if($api >= 2)
    {
      $ffi->attach( [uint32_sum => 'sum3'] => ['uint32*'] => 'uint32' );
      $ffi->attach( [uint32_array_inc => 'array_inc2'] => ['uint32*'] => 'void');
    }

    is add(1,2), 3, 'add(1,2) = 3';
    is do { no warnings; add() }, 0, 'add() = 0';

    my $i = 3;
    is ${inc(\$i, 4)}, 7, 'inc(\$i,4) = \7';

    is $i, 3+4, "i=3+4";

    is ${inc(\3,4)}, 7, 'inc(\3,4) = \7';

    my @list = (1,2,3,4,5,6,7,8,9,10);

    is sum(\@list), 55, 'sum([1..10]) = 55';
    is sum2(\@list, scalar @list), 55, 'sum2([1..10],10) = 55';

    if($api >= 2)
    {
      is(sum3(\@list), 55, 'sum([1..10]) = 55 (passed as pointer)');
    }

    array_inc(\@list);
    do { local $SIG{__WARN__} = sub {}; array_inc() };

    is \@list, [2,3,4,5,6,7,8,9,10,11], 'array increment';

    if($api >= 2)
    {
      @list = (1,2,3,4,5,6,7,8,9,10);
      array_inc2(\@list);
      is \@list, [2,3,4,5,6,7,8,9,10,11], 'array increment';
   }

    is [null()], [$api >= 2 ? (undef) : ()], 'null() == undef';
    is is_null(undef), 1, 'is_null(undef) == 1';
    is is_null(), 1, 'is_null() == 1';
    is is_null(\22), 0, 'is_null(22) == 0';

    is static_array(), [1,4,6,8,10,12,14,16,18,20], 'static_array = [1,4,6,8,10,12,14,16,18,20]';

    is [null2()], [$api >= 2 ? (undef) : ()], 'null2() == undef';

    my $closure = $ffi->closure(sub { $_[0]+2 });
    $ffi->attach( [uint32_set_closure => 'set_closure'] => ['uint32_c'] => 'void');
    $ffi->attach( [uint32_call_closure => 'call_closure'] => ['uint32'] => 'uint32');

    set_closure($closure);
    is call_closure(2), 4, 'call_closure(2) = 4';

    $closure = $ffi->closure(sub { undef });
    set_closure($closure);
    is do { no warnings; call_closure(2) }, 0, 'call_closure(2) = 0';

    subtest 'custom type input' => sub {
      $ffi->custom_type(type1 => { native_type => 'uint32', perl_to_native => sub { is $_[0], 2; $_[0]*2 } });
      $ffi->attach( [uint32_add => 'custom_add'] => ['type1','uint32'] => 'uint32');
      is custom_add(2,1), 5, 'custom_add(2,1) = 5';
    };

    subtest 'custom type output' => sub {
      $ffi->custom_type(type2 => { native_type => 'uint32', native_to_perl => sub { is $_[0], 2; $_[0]*2 } });
      $ffi->attach( [uint32_add => 'custom_add2'] => ['uint32','uint32'] => 'type2');
      is custom_add2(1,1), 4, 'custom_add2(1,1) = 4';
    };

    subtest 'custom type post' => sub {
      $ffi->custom_type(type3 => { native_type => 'uint32', perl_to_native_post => sub { is $_[0], 1 } });
      $ffi->attach( [uint32_add => 'custom_add3'] => ['type3','uint32'] => 'uint32');
      is custom_add3(1,2), 3, 'custom_add3(1,2) = 3';
    };

    $ffi->attach( [pointer_is_null => 'closure_pointer_is_null'] => ['()->void'] => 'int');
    is closure_pointer_is_null(), 1, 'closure_pointer_is_null() = 1';

  };
}

foreach my $api (1,2)
{
  subtest 'object' => sub {

    { package Roger }

    my $ffi = FFI::Platypus->new( api => $api, lib => [@lib], experimental => ($api > 2 ? $api : undef ) );
    $ffi->type('object(Roger,uint32)', 'roger_t');

    my $int = 211;

    subtest 'argument' => sub {

      is $ffi->cast('roger_t' => 'uint32', bless(\$int, 'Roger')), $int;

    };

    subtest 'return value' => sub {

      my $obj1 = $ffi->cast('uint32' => 'roger_t', $int);
      isa_ok $obj1, 'Roger';
      is $$obj1, $int;

    };
  }
};

done_testing;
