use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Capture::Tiny qw( capture_merged );
use FFI::Probe::Runner::Builder;
use IPC::Cmd qw( can_run );

my $dir = tempdir( CLEANUP => 1, DIR => '.', TEMPLATE => 'test-probe-XXXXXX' );

note "dir = $dir";

my $builder = FFI::Probe::Runner::Builder->new(
  dir => $dir,
);

isa_ok $builder, 'FFI::Probe::Runner::Builder';

my($out1, $exe, $error) = capture_merged {
  my $exe = eval { $builder->build };
  ($exe, $@);
};
note $out1;

is $error, '', 'no error';

ok -f $exe, "executable exists";
note "exe = $exe";

my($out2, $ret) = capture_merged {
  print "+ $exe verify self\n";
  system $exe, 'verify', 'self';
  $?;
};

note $out2;
is $ret, 0, 'verify ok';

if($^O eq 'linux' && can_run('ldd'))
{
  note capture_merged {
    print "+ ldd $exe\n";
    system "ldd", $exe;
    ();
  };
}

done_testing;
