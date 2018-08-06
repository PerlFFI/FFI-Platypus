use strict;
use warnings;
use Test::More;
use FFI::Build::Platform;

subtest basic => sub {

  my $platform = FFI::Build::Platform->new;
  isa_ok $platform, 'FFI::Build::Platform';

  note($platform->diag);
};

done_testing;
