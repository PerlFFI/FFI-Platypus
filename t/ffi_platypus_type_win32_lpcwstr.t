use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Platypus::Buffer;
use FFI::Platypus::Memory;
use FFI::CheckLib;
use Encode qw( encode );

my $ffi = FFI::Platypus->new;

$ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi');
$ffi->lang('Win32');
$ffi->attach(lpcwstr_len => ['LPCWSTR'] => 'int');
$ffi->attach(lpcwstr_doubler_static => ['LPCWSTR'] => 'LPCWSTR');
$ffi->attach(lpcwstr_copy_arg => ['LPWSTR','LPCWSTR','size_t'] => 'LPWSTR');
$ffi->attach(lpcwstr_copy_return => ['LPCWSTR'] => 'opaque');
$ffi->attach(lpcwstr_doubler_inplace => ['LPWSTR','size_t'] => 'LPWSTR');

my @strings = (
  [ "trivial" => "" ],
  [ "simple"  => "abcde" ],
  [ "fancy"   => "abcd\x{E9}" ],
  [ "complex" => "I \x{2764} Platypus" ],
);

subtest 'LPCWSTR as argument' => sub {
  for (@strings)
  {
    my ($name, $string) = @$_;
    is lpcwstr_len($string), length($string), $name;
  }
  is lpcwstr_len(undef), -1, "null";
};

subtest 'LPCWSTR as return value' => sub {
  for (@strings)
  {
    my ($name, $string) = @$_;
    is lpcwstr_doubler_static($string), $string.$string, $name;
  }
  is lpcwstr_doubler_static(undef), undef, "null";
};

subtest 'LPWSTR as out argument' => sub {
  my $buf_size = 512;
  my $buf = malloc($buf_size*2);
  for (@strings)
  {
    my ($name, $string) = @$_;
    lpcwstr_copy_arg($buf, $string, $buf_size);
    is $ffi->cast('opaque' => 'LPCWSTR', $buf), $string, $name;
  }
  free($buf);
};

subtest 'LPWSTR as return value' => sub {
  for (@strings)
  {
    my ($name, $string) = @$_;
    my $buf = lpcwstr_copy_return($string);
    is $ffi->cast('opaque' => 'LPCWSTR', $buf), $string, $name;
    free($buf);
  }
};

subtest 'LPWSTR as in-out argument (strcpyW)' => sub {
  my $buf_size = 512;
  my $buf = malloc($buf_size*2);
  for (@strings)
  {
    my ($name, $string) = @$_;
    my $init = encode('UTF16-le', "$string\0");
    my ($init_opaque, $init_size) = scalar_to_buffer($init);
    strcpyW($buf, $init_opaque);
    lpcwstr_doubler_inplace($buf, $buf_size);
    is $ffi->cast('opaque' => 'LPCWSTR', $buf), $string.$string, $name;
  }
  free($buf);
};

subtest 'LPWSTR as in-out argument (strncpyW)' => sub {
  my $buf_size = 512;
  my $buf = calloc($buf_size, 2);
  for (@strings)
  {
    my ($name, $string) = @$_;
    my $init = encode('UTF16-le', "$string\0");
    my ($init_opaque, $init_size) = scalar_to_buffer($init);
    strncpyW($buf, $init_opaque, $buf_size-1);
    lpcwstr_doubler_inplace($buf, $buf_size);
    is $ffi->cast('opaque' => 'LPCWSTR', $buf), $string.$string, $name;
  }
  free($buf);
};

done_testing;
