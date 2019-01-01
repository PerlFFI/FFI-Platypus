use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib;

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi');
$ffi->type('string(10)' => 'string_10');
$ffi->type('string(5)'  => 'string_5');

$ffi->attach( 'string_matches_foobarbaz'     => ['string'] => 'int');
$ffi->attach( 'string_return_foobarbaz'      => []       => 'string');
$ffi->attach( [pointer_null => 'null']       => []       => 'string');
$ffi->attach( [pointer_is_null => 'is_null'] => ['string'] => 'int');

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

my $arg = "foo";
is( string_test_pointer_arg(\$arg), "*arg==foo");
is( $arg, "out" );

undef $arg;
is( string_test_pointer_arg(\$arg), "*arg==NULL");
is( $arg, "out" );

is( string_test_pointer_arg(undef), "arg==NULL");

done_testing;
