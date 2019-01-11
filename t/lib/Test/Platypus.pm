package Test::Platypus;

use strict;
use warnings;
use Test::More ();
use base qw( Exporter );

our @EXPORT = qw( platypus );

sub platypus  {
  my($count, $code) = @_;

  my $ffi = eval {
    require FFI::Platypus;
    FFI::Platypus->VERSION(0.51);
    FFI::Platypus->new;
  };

  SKIP: {
    Test::More::skip "Test requires FFI::Platypus", $count unless $ffi;
    $code->($ffi);
  }
}

1;
