use strict;
use warnings;
use Test::More;
use FFI::Temp;
use Capture::Tiny qw( capture_merged );
use FFI::Probe::Runner::Builder;
use IPC::Cmd qw( can_run );

$FFI::Probe::Runner::Builder::VERBOSE = 1;

my $dir = FFI::Temp->newdir( TEMPLATE => 'test-probe-XXXXXX' );

note "dir = $dir";

my $builder = FFI::Probe::Runner::Builder->new(
  dir => $dir,
);

foreach my $lib (@{ $builder->libs })
{
  note "libs=" . join(' ', @$lib)
}

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
