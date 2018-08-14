use strict;
use warnings;
use Test::More;
use FFI::Platypus::Declare;

my %abis = %{ FFI::Platypus->abis };

plan tests => 2 + scalar keys %abis;

ok defined $abis{default_abi}, 'has a default ABI';

foreach my $abi (keys %abis)
{
  subtest $abi => sub {
    eval { abi $abi };
    is $@, '', 'string';
    eval { abi $abis{$abi} };
    is $@, '', 'integer';
  };
}

subtest 'bogus' => sub {
  eval { abi 'bogus' };
  like $@, qr{no such ABI: bogus}, 'string';
  eval { abi 999999 };
  like $@, qr{no such ABI: 999999}, 'integer';
};
