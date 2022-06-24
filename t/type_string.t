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

    my $p = $api == 0 ? '' : '*';

    my $ffi = FFI::Platypus->new( api => $api, lib => [@lib], experimental => ($api > 2 ? $api : undef ) );
    $ffi->type("string(10)$p" => 'string_10');
    $ffi->type("string(5)$p"  => 'string_5');

    $ffi->attach( 'string_matches_foobarbaz'     => ['string'] => 'int');
    $ffi->attach( 'string_return_foobarbaz'      => []       => 'string');
    $ffi->attach( [pointer_null => 'null']       => []       => 'string');
    $ffi->attach( [pointer_is_null => 'is_null'] => ['string'] => 'int');
    $ffi->attach( 'string_write_to_string'       => ['string','string'] => 'void');

    ok string_matches_foobarbaz("foobarbaz"), "string_matches_foobarbaz(foobarbaz) = true";
    ok !string_matches_foobarbaz("x"), "string_matches_foobarbaz(foobarbaz) = false";
    is string_return_foobarbaz(), "foobarbaz", "string_return_foobarbaz() = foobarbaz";

    is null(), undef, 'null() = undef';
    is is_null(undef), 1, 'is_null(undef) = 1';
    is is_null(), 1, 'is_null() = 1';
    is is_null("foo"), 0, 'is_null("foo") = 0';

    $ffi->attach( [string_set_closure => 'set_closure']   => ['(string)->void'] => 'void');
    $ffi->attach( [string_call_closure => 'call_closure'] => ['string']=>'void');

    my $save = 1;
    my $closure = $ffi->closure(sub { $save = $_[0] });

    set_closure($closure);
    call_closure("hey there");
    is $save, "hey there", "\$save = hey there";

    call_closure(undef);
    is $save, undef, "\$save = undef";


    $ffi->attach( ['string_matches_foobarbaz' => 'fixed_input_test'] => ['string_10'] => 'int');
    $ffi->attach( ['pointer_is_null'          => 'fixed_input_is_null'] => ['string_10'] => 'int');

    is fixed_input_test("foobarbaz\0"), 1, "fixed_input_test(foobarbaz\\0)";
    is fixed_input_is_null(undef), 1, "fixed_input_is_null(undef)";

    $ffi->attach( string_fixed_test => ['int'] => 'string_5');

    is string_fixed_test(0), "zero ", "string_fixed_text(0) = zero";
    is string_fixed_test(1), "one  ", "string_fixed_text(1) = one";
    is string_fixed_test(2), "two  ", "string_fixed_text(2) = two";
    is string_fixed_test(3), "three", "string_fixed_text(3) = three";

    $ffi->attach( [pointer_null => 'fixed_output_null'] => [] => 'string_5');

    is fixed_output_null(), undef, 'fixed_output_null()';

    $ffi->attach( [string_set_closure => 'set_closure_fixed'] => ['(string_5)->void'] => 'void');

    my $closure_fixed = $ffi->closure(sub { $save = $_[0] });

    set_closure_fixed($closure_fixed);
    call_closure("zero one  two  three");
    is $save, "zero ", "save=zero ";

    $ffi->attach( string_test_pointer_arg => [ 'string*' ] => 'string' );

    {
      my $arg = "foo";
      is( string_test_pointer_arg(\$arg), "*arg==foo");
      is( $arg, "out" );
    }

    {
      my $arg;
      is( string_test_pointer_arg(\$arg), "*arg==NULL");
      is( $arg, "out" );
    }

    is( string_test_pointer_arg(undef), "arg==NULL");

    $ffi->attach( string_test_pointer_ret => [ 'string' ] => 'string*' );
    $ffi->attach( [ pointer_null => 'string_test_pointer_ret_null' ] => [] => 'string*' );

    is( string_test_pointer_ret("foo"), \"foo" );
    is( string_test_pointer_ret(undef), \undef );
    is( [string_test_pointer_ret_null()], [$api >= 2 ? (undef) : ()] );

    subtest 'fixed length input' => sub {

      $ffi->type('string[5]' => 'string_5_undef');

      my $a2 = $ffi->function(get_string_from_array => ['string_5_undef', 'int'] => 'string');

      my @list = ( 'foo', 'bar', 'baz', undef, 'five', 'six' );

      subtest 'with default' => sub {
        is $a2->(\@list, 0), 'foo', 'a2(0) = foo';
        is $a2->(\@list, 1), 'bar', 'a2(0) = bar';
        is $a2->(\@list, 2), 'baz', 'a2(0) = baz';
        is $a2->(\@list, 3), undef, 'a2(0) = undef';
        is $a2->(\@list, 4), 'five', 'a2(0) = five';
      };

    };

    subtest 'variable length input' => sub {

      $ffi->type('string[]' => 'sa');

      my $get_string_from_array = $ffi->function(get_string_from_array => ['sa','int'] => 'string');

      my @list = ('foo', 'bar', 'baz', undef );

      for(0..2)
      {
        is $get_string_from_array->(\@list, $_), $list[$_], "get_string_from_array(\@list, $_) = $list[$_]";
      }

      is $get_string_from_array->(\@list, 3), undef, "get_string_from_array(\@list, 3) = undef";
    };

    subtest 'variable length input' => sub {

      skip_all 'test requires api >=2'
        unless $api >= 2;

      my $get_string_from_array = $ffi->function(get_string_from_array => ['string*','int'] => 'string');

      my @list = ('foo', 'bar', 'baz', undef );

      for(0..2)
      {
        is $get_string_from_array->(\@list, $_), $list[$_], "get_string_from_array(\@list, $_) = $list[$_]";
      }

      is $get_string_from_array->(\@list, 3), undef, "get_string_from_array(\@list, 3) = undef";
    };

    subtest 'fixed length return' => sub {

      $ffi->type('string[3]' => 'sa3');

      is(
        $ffi->function(pointer_null => [] => 'sa3')->call,
        undef,
        'returns null',
      );

      is(
        $ffi->function(onetwothree3 => [] => 'sa3')->call,
        [ qw( one two three ) ],
        'returns with just strings',
      );

      is(
        $ffi->function(onenullthree3 => [] => 'sa3')->call,
        [ 'one', undef, 'three' ],
        'returns with NULL/undef in the middle',
      );

    };

    subtest 'null terminated return' => sub {

      is(
        $ffi->function(pointer_null => [] => 'sa')->call,
        undef,
        'returns null',
      );

      is(
        $ffi->function('onetwothree4', => [] => 'sa')->call,
        [ qw( one two three ) ],
      );

      is(
        $ffi->function('onenullthree3' => [] => 'sa')->call,
        [ qw( one ) ],
      );

      is(
        $ffi->function('ptrnull' => [] => 'sa')->call,
        [],
      );

    };

    subtest 'argument update' => sub {

      my @args = ( undef, 'six', 'xx' );
      $ffi->function( string_array_arg_update => [ 'string[3]' ] => 'void' )->call(\@args);
      is(
        \@args,
        [ "one", "two", "xx" ],
      );

    };

    subtest 'write to string' => sub {

      my $src = 'hello world';
      my $dst = ' ' x (length($src)+1);
      string_write_to_string($dst, $src);
      is($dst, "hello world\0");

    };

    is(
      [$ffi->function( pointer_null => [] => 'string' )->call],
      [$api >= 2 ? (undef) : ()],
    );

  };
}

done_testing;

