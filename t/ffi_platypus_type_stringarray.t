use strict;
use warnings;
use Test::More;
use FFI::CheckLib;
use FFI::Platypus;

my $libtest = find_lib lib => 'test', libpath => 't/ffi';

my $ffi = FFI::Platypus->new;
$ffi->lib($libtest);

subtest 'fixed length input' => sub {

  $ffi->load_custom_type('::StringArray' => 'string_5_hey' => 5, "hey");
  $ffi->load_custom_type('::StringArray' => 'string_5_undef' => 5, undef);

  my $a1 = $ffi->function(get_string_from_array => ['string_5_hey',  'int'] => 'string');
  my $a2 = $ffi->function(get_string_from_array => ['string_5_undef', 'int'] => 'string');

  my @list = ( 'foo', 'bar', 'baz', undef, 'five', 'six' );

  subtest 'with default' => sub {
    is $a1->(\@list, 0), 'foo', 'a1(0) = foo';
    is $a1->(\@list, 1), 'bar', 'a1(0) = bar';
    is $a1->(\@list, 2), 'baz', 'a1(0) = baz';
    is $a1->(\@list, 3), 'hey', 'a1(0) = hey';
    is $a1->(\@list, 4), 'five', 'a1(0) = five';
    is $a1->(\@list, 5), undef, 'a1(0) = undef';
  };

  subtest 'with default' => sub {
    is $a2->(\@list, 0), 'foo', 'a2(0) = foo';
    is $a2->(\@list, 1), 'bar', 'a2(0) = bar';
    is $a2->(\@list, 2), 'baz', 'a2(0) = baz';
    is $a2->(\@list, 3), undef, 'a2(0) = undef';
    is $a2->(\@list, 4), 'five', 'a2(0) = five';
    is $a2->(\@list, 5), undef, 'a2(0) = undef';
  };

};

subtest 'variable length input' => sub {

  $ffi->load_custom_type('::StringArray' => 'sa');

  my $get_string_from_array = $ffi->function(get_string_from_array => ['sa','int'] => 'string');

  my @list = qw( foo bar baz );

  for(0..2)
  {
    is $get_string_from_array->(\@list, $_), $list[$_], "get_string_from_array(\@list, $_) = $list[$_]";
  }

  is $get_string_from_array->(\@list, 3), undef, "get_string_from_array(\@list, 3) = undef";
};

subtest 'fixed length return' => sub {

  $ffi->load_custom_type('::StringArray' => 'sa3' =>  3);
  $ffi->load_custom_type('::StringArray' => 'sa3x' =>  3, 'x');

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

  is_deeply(
    $ffi->function(onenullthree3 => [] => 'sa3x')->call,
    [ 'one', 'x', 'three' ],
    'returns with NULL/undef in the middle with default',
  );

};

subtest 'null terminated return' => sub {

  #$ffi->load_custom_type('::StringArray' => 'sa');

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
