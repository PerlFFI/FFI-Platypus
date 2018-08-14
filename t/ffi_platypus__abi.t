use strict;
use warnings;
use Test::More;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;

my %abis = %{ $ffi->abis };

plan tests => 2 + scalar keys %abis;

ok defined $abis{default_abi}, 'has a default ABI';

foreach my $abi (keys %abis)
{
  subtest $abi => sub {
    eval { $ffi->abi($abi) };
    is $@, '', 'string';
    eval { $ffi->abi($abis{$abi}) };
    is $@, '', 'integer';
  };
}

subtest 'bogus' => sub {
  eval { $ffi->abi('bogus') };
  like $@, qr{no such ABI: bogus}, 'string';
  eval { $ffi->abi(999999) };
  like $@, qr{no such ABI: 999999}, 'integer';
};
