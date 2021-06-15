use Test2::V0 -no_srand => 1;
use Config;
use Capture::Tiny qw( capture_merged );
use FFI::Temp;

# libexpat1-dev

plan skip_all => 'tested only in CI' if ($ENV{CIPSOMETHING}||'') ne 'true';
plan skip_all => 'tested only in CI -debug' if $Config{ccflags} !~ /-DDEBUG_LEAKING_SCALARS/;

my %exfail = map { $_ => 1 } qw( attach.pl );

# you can run this on just one (or more) test file in corpus/memory by
#  perl -Mblib t/memory.t foo.pl

my @list = @ARGV ? @ARGV : do {
  my $dh;
  opendir $dh, 'corpus/memory';
  grep /\.pl$/, sort readdir $dh;
};

my @supp = do {
  my $dh;
  opendir $dh, 'corpus/memory/supp';
  map { "--suppressions=corpus/memory/supp/$_" } grep /\.supp/, sort readdir $dh;
};

foreach my $name (@list)
{
  subtest $name => sub {

    local $ENV{PERL_DESTRUCT_LEVEL} = 2;

    my $log = FFI::Temp->new;

    my @command = (
      'valgrind',
      '--leak-check=yes',
      "--log-file=$log",
      '--error-exitcode=2',
      #'--gen-suppressions=all',
      #'-v',
      @supp,
      $^X,
      '-Mblib',
      "corpus/memory/$name",
    );

    my($out, $exit) = capture_merged {
      print "+ @command\n";
      system @command;
      $?;
    };

    if($exfail{$name})
    {
      note "expected fail";
      {
        my $todo = todo 'expected fail';
        is($exit, 0, 'valgrind') or do {
          note "[output]\n$out";
          note "[log]\n", do { local $/; <$log> };
        };
      };
    }
    else
    {
      note "expected pass";
      is($exit, 0, 'valgrind') or do {
        diag "[output]\n$out";
        diag "[log]\n", do { local $/; <$log> };
      };
    }

  };
}

done_testing;
