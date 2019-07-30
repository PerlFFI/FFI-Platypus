use strict;
use warnings;
use Test::More;
use FFI::Platypus::Bundle::API;

subtest 'very very basic...' => sub {

  my $api = FFI::Platypus::Bundle::API->new;
  isa_ok $api, 'FFI::Platypus::Bundle::API';
  undef $api;
  ok 'did not appear to crash :tada:';

};

done_testing;
