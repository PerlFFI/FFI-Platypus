use strict;
use warnings;
use File::Basename qw( basename );
use File::Path qw( mkpath );
use lib 'inc';
use My::Config;
use lib 'lib';
use FFI::Build;
use Config ();

my $config = My::Config->new;

my $lib = FFI::Build->new(
  'plfill',
  source   => ['ffi/*.c'],
  verbose  => (!!$ENV{V} ? 2 : 1),
  dir      => 'blib/lib/auto/share/dist/FFI-Platypus/lib',
  platform => $config->platform,
  alien    => [$config->alien],
)->build;

my $name = basename($lib->basename);

foreach my $dir ( 'FFI/Platypus/Memory','FFI/Platypus/Record/Meta' )
{
  my($file) = $dir =~ m{/([^/]+)$};
  mkpath("blib/arch/auto/$dir", 0, 0755);
  my $txtfile = "blib/arch/auto/$dir/$file.txt";
  my $fh;
  open($fh, '>', $txtfile) || die "unable to write to $txtfile $!";
  print $fh "FFI::Build\@auto/share/dist/FFI-Platypus/lib/$name\n";
  close $fh;
}
