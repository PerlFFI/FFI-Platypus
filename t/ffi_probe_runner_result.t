use strict;
use warnings;
use Test::More;
use FFI::Probe::Runner::Result;

my %std = ( stdout => "foo\n", stderr => "bar\n", rv => 0, signal => 0 );

my $result1 = FFI::Probe::Runner::Result->new(
  %std
);

isa_ok $result1, 'FFI::Probe::Runner::Result';
ok($result1->pass);

my $result2 = FFI::Probe::Runner::Result->new(
  %std,
  rv => 2,
);

isa_ok $result2, 'FFI::Probe::Runner::Result';
is($result2->rv, 2);
ok(!$result2->pass);

my $result3 = FFI::Probe::Runner::Result->new(
  %std,
  signal => 9,
);

isa_ok $result3, 'FFI::Probe::Runner::Result';
is($result3->signal, 9);
ok(!$result3->pass);

done_testing;
