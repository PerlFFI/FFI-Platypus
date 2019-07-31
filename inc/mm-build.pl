use strict;
use warnings;
use File::Basename qw( basename );
use File::Path qw( mkpath );
use File::Copy qw( copy );
use lib 'inc';
use My::Config;
use lib 'lib';
use FFI::Build;
use Config ();

my $config = My::Config->new;

my $include = "blib/lib/auto/share/dist/FFI-Platypus/include";
mkpath $include, 0, 0755;
foreach my $h (qw( ffi_platypus_config.h ffi_platypus_bundle.h ))
{
  my $from = "include/$h";
  my $to   = "$include/$h";

  if(-f $to)
  {
    next if slurp($from) eq slurp($to);
  }

  copy($from => $to) || die "unable to copy $from => $to $!";
}

my $lib = FFI::Build->new(
  'plfill',
  source   => ['ffi/*.c'],
  verbose  => (!!$ENV{V} ? 2 : 1),
  dir      => 'blib/lib/auto/share/dist/FFI-Platypus/lib',
  platform => $config->platform,
  alien    => [$config->alien],
  cflags   => '-Iblib/lib/auto/share/dist/FFI-Platypus/include',
)->build;

my $name = basename($lib->basename);

foreach my $dir ( 'FFI/Platypus/Memory','FFI/Platypus/Record/Meta', 'FFI/Platypus/Bundle/Constant' )
{
  my($file) = $dir =~ m{/([^/]+)$};
  mkpath("blib/arch/auto/$dir", 0, 0755);
  my $txtfile = "blib/arch/auto/$dir/$file.txt";
  my $fh;
  open($fh, '>', $txtfile) || die "unable to write to $txtfile $!";
  print $fh "FFI::Build\@auto/share/dist/FFI-Platypus/lib/$name\n";
  close $fh;
}

sub slurp
{
  my($filename) = @_;
  my $fh;
  open $fh, '<', $filename;
  binmode $fh;
  my $content = do { local $/; <$fh> };
  close $fh;
  $content;
}
