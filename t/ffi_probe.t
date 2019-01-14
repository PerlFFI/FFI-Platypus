use strict;
use warnings;
use Test::More;
use FFI::Probe;
use FFI::Probe::Runner;
use Capture::Tiny qw( capture_merged );
use File::Temp qw( tempdir );
use File::Basename qw( basename );
use Config;

sub n (&)
{
  my($code) = @_;
  my($out, @ret) = capture_merged {
    $code->();
  };
  note $out;
  @ret;
}

sub f (@)
{
  foreach my $filename (@_)
  {
    note "==@{[ basename $filename ]}==";
    my $fh;
    open $fh, '<', $filename;
    note do { local $/; <$fh> };
    close $fh;
  }
}

my $runner = do {
  my $exe = "blib/lib/auto/share/dist/FFI-Platypus/probe/bin/dlrun$Config{exe_ext}";

  unless(-f $exe)
  {
    require FFI::Probe::Runner::Builder;
    require File::Temp;
    my $out;
    my $exception;
    ($out, $exe, $exception) = capture_merged {
      my $exe = eval {
        FFI::Probe::Runner::Builder->new( dir => File::Temp::tempdir( CLEANUP => 1, TEMPLATE => 'test-probe-XXXXXX', DIR => '.' ) )->build;
      };
      ($exe, $exception);
    };
    note $out;
    die $exception if $exception;
  }

  FFI::Probe::Runner->new(
    exe => $exe,
  );
  
};

subtest 'check_header' => sub {

  my $dir = tempdir( CLEANUP => 1 );

  my $probe = FFI::Probe->new(
    log           => "$dir/probe.log",
    data_filename => "$dir/probe.pl",
    runner        => $runner,
  );

  isa_ok $probe, 'FFI::Probe';

  n {
    $probe->check_header('stdio.h');
    $probe->check_header('bogus/does/not/exist.h');
  };

  is($probe->data->{header}->{"stdio.h"}, 1);
  is($probe->data->{header}->{"bogus/does/not/exist.h"}, 0);

  undef $probe;

  f "$dir/probe.log",
    "$dir/probe.pl";

  # make sure that we cache that data correctly.
  my $probe2 = FFI::Probe->new(
    log           => "$dir/probe2.log",
    data_filename => "$dir/probe.pl",
    runner        => $runner,
  );

  is($probe2->data->{header}->{"stdio.h"}, 1);
  is($probe2->data->{header}->{"bogus/does/not/exist.h"}, 0);

  n {
    $probe2->check_header('stdio.h');
    $probe2->check_header('bogus/does/not/exist.h');
  };

  is($probe2->data->{header}->{"stdio.h"}, 1);
  is($probe2->data->{header}->{"bogus/does/not/exist.h"}, 0);

  f "$dir/probe2.log",
    "$dir/probe.pl";
};

subtest check_eval => sub {

  my $dir = tempdir( CLEANUP => 1 );

  # make sure that we cache that data correctly.
  my $probe = FFI::Probe->new(
    log           => "$dir/probe.log",
    data_filename => "$dir/probe.pl",
    runner        => $runner,
  );

  my $ret;

  n {
    $ret = $probe->check_eval(
      eval => {
        'foo.bar.baz' => [ '%d' => '1+2' ],
      },
    );
  };

  ok $ret, 'foo.bar.baz';
  is_deeply $probe->data, { foo => { bar => { baz => 3 } } };

  n {
    $ret = $probe->check_eval(
      decl => ['char buffer[256];'],
      stmt => ['sprintf(buffer, "hello world %d", 3+4);'],
      eval => {
        'foo.bar.string' => [ '%s' => 'buffer' ],
      },
    );
  };

  ok $ret, 'foo.bar.string';
  is_deeply $probe->data, { foo => { bar => { baz => 3, string => 'hello world 7' } } };

  n {
    $ret = $probe->check_type_int('unsigned char');
  };

  is $ret, 'uint8';
  is $probe->data->{type}->{'unsigned char'}->{size}, 1;
  is $probe->data->{type}->{'unsigned char'}->{sign}, 'unsigned';
  like $probe->data->{type}->{'unsigned char'}->{align}, qr/^[0-9]+$/;

  n {
    $ret = $probe->check_type_float('float');
  };

  is $ret, 'float';
  is $probe->data->{type}->{'float'}->{size}, 4;
  like $probe->data->{type}->{'float'}->{align}, qr/^[0-9]+$/;

  n {
    $ret = $probe->check_type_pointer;
  };

  is $ret, 'pointer';
  like $probe->data->{type}->{pointer}->{size}, qr/^[0-9]+$/;
  like $probe->data->{type}->{pointer}->{align}, qr/^[0-9]+$/;

  $probe->save;
  undef $probe;

  f "$dir/probe.log",
    "$dir/probe.pl";

};

done_testing;
