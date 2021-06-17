package Test::Platypus;

use strict;
use warnings;
use Test2::API qw( context );
use Exporter qw( import );

our @EXPORT = qw( platypus );

sub platypus  {
  my($count, $code) = @_;

  my $ffi = eval {
    require FFI::Platypus;
    FFI::Platypus->new;
  };

  if($ffi)
  {
    $code->($ffi);
  }
  else
  {
    my $ctx = context();
    $ctx->skip('', "Test requires FFI::Platypus") for 1..$count;
    $ctx->release;
  }

}

1;
