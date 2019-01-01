use strict;
use warnings;
use Test::More;
use FFI::CheckLib;
use FFI::Platypus;

my $libtest = find_lib lib => 'test', libpath => 't/ffi';

my $ffi = FFI::Platypus->new;
$ffi->lib($libtest);

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

subtest 'fixed length return' => sub {

  $ffi->type('string[3]' => 'sa3');

  is(
    $ffi->function(pointer_null => [] => 'sa3')->call,
    undef,
    'returns null',
  );

  is_deeply(
    $ffi->function(onetwothree3 => [] => 'sa3')->call,
    [ qw( one two three ) ],
    'returns with just strings',
  );

  is_deeply(
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

  is_deeply(
    $ffi->function('onetwothree4', => [] => 'sa')->call,
    [ qw( one two three ) ],
  );

  is_deeply(
    $ffi->function('onenullthree3' => [] => 'sa')->call,
    [ qw( one ) ],
  );

  is_deeply(
    $ffi->function('ptrnull' => [] => 'sa')->call,
    [],
  );

};

done_testing;
