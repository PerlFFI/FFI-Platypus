use strict;
use warnings;
use open ':std', ':encoding(utf8)';
use Test::More;
use FFI::CheckLib;
use FFI::Platypus;
use FFI::Platypus::Memory qw( free strdup );
use FFI::Platypus::Type::WideString;

my($encoding,$width) = eval { FFI::Platypus::Type::WideString->_compute_wide_string_encoding() };

if(my $error = $@)
{
  $error =~ s/ at .*$//;
  plan skip_all => "Unable to detect wide string details: $error\n";
}

# This test assumes a wchar_t of at least 2 bytes, which is probably true
# everywhere Platypus is actually suppored, but wchar_t could technically
# be the same size as char.

note "encoding = $encoding";
note "width    = $width";

my @lib = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';  # need test lib for pointer_is_null
push @lib, undef;                                                      # for libc wcs* functions

my $ffi = FFI::Platypus->new( api => 1, lib => \@lib );
$ffi->ignore_not_found(1);
$ffi->load_custom_type('::WideString' => 'wstring');
$ffi->load_custom_type('::WideString' => 'wstring_w', access => 'write');

my $wcsdup = do {

  our $ptr;
  my $wrapper = sub {
    my $xsub = shift;
    free $ptr if defined $ptr;
    $ptr = undef;
    $ptr = $xsub->(@_);
  };

  my $wcsdup = $ffi->function( wcsdup => ['wstring'] => 'opaque' => $wrapper);

  $wcsdup = $ffi->function( _wcsdup => ['wstring'] => 'opaque' => $wrapper)
    if $^O eq 'MSWin32' && ! defined $wcsdup;

  END { free $ptr if defined $ptr; undef $ptr };

  $wcsdup;
};

subtest 'wcschr' => sub {

  my $wcschr = $ffi->function( wcschr => ['opaque','wchar_t'] => 'wstring' );
  plan skip_all => 'Test requires wcschr' unless defined $wcschr;
  plan skip_all => 'Test requires wcsdup' unless defined $wcsdup;

  is( $ffi->cast( opaque => 'wstring', $wcsdup->call("I \x{2764} Platypus")), "I \x{2764} Platypus" );

  # make sure libc is using the same wchar_t as we are.
  # also tests "in as argument" mode.
  is( $wcschr->call($wcsdup->call('foobar'),              ord('b')),        'bar');
  is( $wcschr->call($wcsdup->call("I \x{2764} Platypus"), ord("\x{2764}")), "\x{2764} Platypus");

};

my @strings = (
  [ "trivial" => "" ],
  [ "simple"  => "abcde" ],
  [ "fancy"   => "abcd\x{E9}" ],
  [ "complex" => "I \x{2764} Platypus" ],
);

subtest 'wide string as argument (in)' => sub {

  my $wcslen = $ffi->function( wcslen => ['wstring'] => 'size_t' );
  plan skip_all => 'Test requires wcslen' unless defined $wcslen;

  foreach my $test (@strings)
  {
    my($name, $string) = @$test;
    # note: this works because on Windows with UTF_16
    # because all of our test strings are in the BMP
    is($wcslen->call($string), length($string), $name);
  }

  is($ffi->cast( 'wstring', 'opaque', undef), undef, 'NULL');

};

subtest 'wide string as argument (out)' => sub {

  my $wcscpy = $ffi->function( wcscpy => ['wstring_w','wstring'] => 'wstring' );
  plan skip_all => 'Test requires wcscpy' unless defined $wcscpy;

  foreach my $test (@strings)
  {
    my($name, $string) = @$test;

    my $out1;
    $wcscpy->call(\$out1, $string);
    is($out1, $string, "$name default buffer size");

    my $out2 = "\0" x ($width * (length($string)+1));
    $wcscpy->call(\$out2, $string);
    is($out2, $string, "$name with just enough buffer");
  }

  my $is_null = $ffi->function( pointer_is_null => ['wstring_w'] => 'int' );
  ok($is_null->call(undef), "NULL");
};

subtest 'wide string as a return value' => sub {

  plan skip_all => 'Test requires wcsdup' unless defined $wcsdup;

  foreach my $test (@strings)
  {
    my($name, $string) = @$test;
    my $ptr = $wcsdup->($string);
    is($ffi->cast('opaque','wstring', $ptr), $string, $name);
  }

  is($ffi->cast('opaque','wstring', undef), undef, 'NULL');

};

subtest 'wide string as in-out argument' => sub {

  my $wcscat = $ffi->function( wcscat => ['wstring_w','wstring'] => 'wstring' );
  plan skip_all => 'Test requires wcscat' unless defined $wcscat;

  foreach my $test (@strings)
  {
    my($name, $string) = @$test;

    my $out1;
    $wcscat->call([\$out1, $string], $string);
    is($out1, "$string$string", "$name default buffer size");

    my $out2 = "\0" x ($width * (length($string)*2+1));
    $wcscat->call([\$out2, $string], $string);
    is($out2, "$string$string", "$name with just enough buffer");
  }

};

done_testing;
