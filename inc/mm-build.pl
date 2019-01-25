use strict;
use warnings;
use File::Basename qw( basename );
use File::Path qw( mkpath );
use lib 'lib';
use FFI::Build;

my $lib = FFI::Build->new(
  'plfill',
  source => ['ffi/*.c'],
  verbose => (!!$ENV{V} ? 2 : 1),
  dir => 'blib/lib/auto/share/dist/FFI-Platypus/lib',
)->build;

my $name = basename($lib->basename);

foreach my $mod (qw( Memory ))
{
  mkpath("blib/arch/auto/FFI/Platypus/$mod", 0, 0755);
  my $txtfile = "blib/arch/auto/FFI/Platypus/$mod/$mod.txt";
  my $fh;
  open($fh, '>', $txtfile) || die "unable to write to $txtfile $!";
  print $fh "FFI::Build\@auto/share/dist/FFI-Platypus/lib/$name\n";
  close $fh;
}
