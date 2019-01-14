use strict;
use warnings;
use Test::More;
use Config;
use FFI::Probe::Runner;
use Capture::Tiny qw( capture_merged );
use FFI::Build;
use FFI::Build::File::C;
use File::Temp qw( tempdir );
use lib 't/lib';
use Test::Cleanup;

my $runner;

subtest basic => sub {

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

  note "exe=$exe";

  $runner = FFI::Probe::Runner->new(
    exe => $exe,
  );

  isa_ok $runner, 'FFI::Probe::Runner';
  is($runner->flags, '-');

  is($runner->verify, 1);

};

subtest 'run not pass' => sub {

  my $lib = do {
    my $dir = tempdir( CLEANUP => 1, TEMPLATE => 'test-probe-XXXXXX', DIR => '.' ); 
    my $build = FFI::Build->new(
      'frooble1',
      dir => $dir,
      buildname => "test-probe-$$-@{[ time ]}",
      verbose => 1,
      source => 'corpus/ffi_probe_runner/foo.c',
    );
    note capture_merged {
      $build->build;
      ();
    };
    cleanup("corpus/ffi_probe_runner/@{[ $build->buildname ]}");
    $build->file->path;
  };


  note "lib=$lib";

  my $res = $runner->run($lib, 'one','two','three');

  is($res->rv, 12);
  is($res->signal, 0);
  like($res->stdout, qr!argc=4!ms);
  like($res->stdout, qr!argv\[0\]=.*/bin/dlrun!ms);
  like($res->stdout, qr!argv\[1\]=one!ms);
  like($res->stdout, qr!argv\[2\]=two!ms);
  like($res->stdout, qr!argv\[3\]=three!ms);
  like($res->stderr, qr/something to std error/);
  ok(!$res->pass);

};

subtest 'run pass' => sub {

  my $lib = do {
    my $dir = tempdir( CLEANUP => 1, TEMPLATE => 'test-probe-XXXXXX', DIR => '.' ); 
    my $build = FFI::Build->new(
      'frooble2',
      verbose => 1,
      dir => $dir,
      buildname => "test-probe-$$-@{[ time ]}",
      source => 'corpus/ffi_probe_runner/bar.c',
    );
    note capture_merged {
      $build->build;
      ();
    };
    cleanup("corpus/ffi_probe_runner/@{[ $build->buildname ]}");
    $build->file->path;
  };

  note "lib=$lib";

  my $res = $runner->run($lib, 'one','two','three');

  is($res->rv, 0);
  is($res->signal, 0);
  like($res->stdout, qr!argc=4!ms);
  like($res->stdout, qr!argv\[0\]=.*/bin/dlrun!ms);
  like($res->stdout, qr!argv\[1\]=one!ms);
  like($res->stdout, qr!argv\[2\]=two!ms);
  like($res->stdout, qr!argv\[3\]=three!ms);
  like($res->stderr, qr/something to std error/);
  ok(!!$res->pass);

};

done_testing;
