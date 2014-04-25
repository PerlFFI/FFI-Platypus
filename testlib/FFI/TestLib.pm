package
  FFI::TestLib;

use strict;
use warnings;
use File::Spec;
use File::Basename qw( dirname );

sub config
{
  my $fn = File::Spec->catfile(dirname(__FILE__), File::Spec->updir, 'ffi_testlib.txt');
  my $fh;
  open($fh, '<', $fn) or die "unable to open $fn $!";
  my $pl = do { local $/; <$fh> };
  close $fh;
  my $config = do { no strict; eval $pl };
  die $@ if $@;
  $config;
}

1;
