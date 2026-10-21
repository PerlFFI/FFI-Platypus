use Test2::V0 -no_srand => 1;
use Config;
use File::Temp qw( tempdir );
use List::Util qw( any );
use File::Path qw( rmtree );
use File::Spec;
use Capture::Tiny qw( capture );
use FFI::Build;
use FFI::Platypus::ShareConfig;

# gh#399: a closure called from a thread created by a C library should
# abort with a diagnostic, rather than crash or (worse) appear to work.

my $probe = FFI::Platypus::ShareConfig->get('probe');
my $detect = $^O eq 'MSWin32'
  || $Config{usemultiplicity}
  || any { $probe->{$_} } qw( tls_c11 tls_gnu tls_msvc pthread );

skip_all 'no way to detect the calling thread on this platform' unless $detect;

my $tmp = tempdir( CLEANUP => 1 );

my $lib = do {
  my $build = FFI::Build->new(
    'foreign',
    source  => ['corpus/ffi_platypus_closure_thread/foreign.c'],
    dir     => $tmp,
    buildname => "_build_$$",
    libs    => $^O eq 'MSWin32' ? [] : ['-lpthread'],
    verbose => 1,
  );
  my($out, $err, $lib) = capture { eval { $build->build } };
  note $out, $err;
  rmtree "corpus/ffi_platypus_closure_thread/_build_$$";
  skip_all 'unable to build helper library' unless $lib;
  "$lib";
};

sub run_child
{
  my($func) = @_;
  # write the child script to a file, since a multi-line -e does not
  # survive the command line quoting on Windows.
  my $script = File::Spec->catfile($tmp, 'child.pl');
  open my $fh, '>', $script or die "unable to write $script: $!";
  print $fh <<'PERL';
    use FFI::Platypus;
    my($lib, $func) = @ARGV;
    my $ffi = FFI::Platypus->new( api => 2, lib => $lib );
    my $closure = $ffi->closure(sub { $_[0] * 2 });
    my $ret = $ffi->function( $func => ['(int)->int', 'int'] => 'int' )->call($closure, 21);
    print "ret=$ret\n";
PERL
  close $fh;
  my($out, $err, $exit) = capture {
    system $^X, (map { "-I$_" } grep { !ref } @INC), $script, $lib, $func;
  };
  note "[$func] stdout: $out";
  note "[$func] stderr: $err";
  note "[$func] exit:   $exit";
  ($out, $err, $exit);
}

subtest 'same thread works' => sub {
  my($out, $err, $exit) = run_child('call_in_same_thread');
  is $exit, 0, 'exit status';
  like $out, qr/^ret=42$/m, 'closure was called';
};

subtest 'foreign thread aborts with a diagnostic' => sub {
  my($out, $err, $exit) = run_child('call_in_foreign_thread');
  isnt $exit, 0, 'non-zero exit status';
  unlike $out, qr/ret=/, 'closure did not return';
  like $err, qr/FFI::Platypus: a closure was called from a thread other than the Perl/, 'diagnostic';
};

done_testing;
