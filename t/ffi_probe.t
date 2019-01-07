use strict;
use warnings;
use Test::More;
use FFI::Probe;
use Capture::Tiny qw( capture_merged );
use File::Temp qw( tempdir );
use File::Basename qw( basename );

sub n (&)
{
  my($code) = @_;
  my($out, @ret) = capture_merged {
    $code->();
  };
  note $out;
  @ret;
}

sub f ($)
{
  my($filename) = @_;

  note "==@{[ basename $filename ]}==";
  my $fh;
  open $fh, '<', $filename;
  note do { local $/; <$fh> };
  close $fh;
}

subtest 'check_header' => sub {

  my $dir = tempdir( CLEANUP => 1 );

  my $probe = FFI::Probe->new(
    log           => "$dir/probe.log",
    data_filename => "$dir/probe.pl",
  );

  isa_ok $probe, 'FFI::Probe';

  n {
    $probe->check_header('stdio.h');
    $probe->check_header('bogus/does/not/exist.h');
  };

  is($probe->data->{header}->{"stdio.h"}, 1);
  is($probe->data->{header}->{"bogus/does/not/exist.h"}, 0);

  undef $probe;

  f "$dir/probe.log";
  f "$dir/probe.pl";

  # make sure that we cache that data correctly.
  my $probe2 = FFI::Probe->new(
    log           => "$dir/probe2.log",
    data_filename => "$dir/probe.pl",
  );

  is($probe2->data->{header}->{"stdio.h"}, 1);
  is($probe2->data->{header}->{"bogus/does/not/exist.h"}, 0);

  n {
    $probe2->check_header('stdio.h');
    $probe2->check_header('bogus/does/not/exist.h');
  };

  is($probe2->data->{header}->{"stdio.h"}, 1);
  is($probe2->data->{header}->{"bogus/does/not/exist.h"}, 0);

  f "$dir/probe2.log";
  f "$dir/probe.pl";
};

done_testing;
