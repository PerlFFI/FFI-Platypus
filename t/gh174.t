use strict;
use warnings;
use Test::More;
use Config;
use Capture::Tiny qw( capture_merged );
use FFI::Temp;

# libexpat1-dev

plan skip_all => 'tested only in CI' if ($ENV{CIPSOMETHING}||'') ne 'true';
plan skip_all => 'tested only in CI -debug' if $Config{ccflags} !~ /-DDEBUG_LEAKING_SCALARS/;

my @list = do {
  my $dh;
  opendir $dh, 'corpus/gh174';
  grep /\.pl$/, readdir $dh;
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
      $^X,
      '-Mblib',
      "corpus/gh174/$name",
    );

    my($out, $exit) = capture_merged {
      print "+ @command\n";
      system @command;
      $?;
    };

    is($exit, 0, 'valgrind') or do {
      diag "[output]\n$out";
      diag "[log]\n", do { local $/; <$log> };
    };

  };
}

done_testing;
