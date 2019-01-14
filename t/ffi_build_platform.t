use strict;
use warnings;
use Test::More;
use FFI::Build::Platform;
use Capture::Tiny qw( capture_merged );

subtest basic => sub {

  my $platform = FFI::Build::Platform->new;
  isa_ok $platform, 'FFI::Build::Platform';

  note($platform->diag);
};

subtest 'cc mm works' => sub {

  my $platform = FFI::Build::Platform->new;
  
  my($out, $cc_mm_works) = capture_merged {
    $platform->cc_mm_works(1);
  };
  
  note $out;
  
  ok(defined $cc_mm_works);
  note "cc_mm_works = $cc_mm_works";

};

done_testing;
