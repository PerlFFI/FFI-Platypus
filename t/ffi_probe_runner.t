use Test2::V0 -no_srand => 1;
use Config;
use FFI::Probe::Runner;
use Capture::Tiny qw( capture_merged );
use FFI::Build;
use FFI::Build::File::C;
use FFI::Temp;
use lib 't/lib';
use Test::Cleanup;

my $runner;
my $tempdir = FFI::Temp->newdir( TEMPLATE => 'test-probe-XXXXXX' );

subtest basic => sub {

  my $exe = "blib/lib/auto/share/dist/FFI-Platypus/probe/bin/dlrun$Config{exe_ext}";

  unless(-f $exe)
  {
    require FFI::Probe::Runner::Builder;
    my $out;
    my $exception;
    ($out, $exe, $exception) = capture_merged {
      my $exe = eval {
        FFI::Probe::Runner::Builder->new( dir => $tempdir )->build;
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

  my $dir = FFI::Temp->newdir( TEMPLATE => 'test-probe-XXXXXX' );

  my $lib = do {
    my $build = FFI::Build->new(
      'frooble1',
      dir => $dir,
      buildname => "test-probe-$$-@{[ time ]}",
      verbose => 1,
      source => 'corpus/ffi_probe_runner/foo.c',
      export => ['dlmain'],
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

  my $dir = FFI::Temp->newdir( TEMPLATE => 'test-probe-XXXXXX' );

  my $lib = do {
    my $build = FFI::Build->new(
      'frooble2',
      verbose => 1,
      dir => $dir,
      buildname => "test-probe-$$-@{[ time ]}",
      source => 'corpus/ffi_probe_runner/bar.c',
      export => ['dlmain'],
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
