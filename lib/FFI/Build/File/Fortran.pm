package FFI::Build::File::Fortran;

use strict;
use warnings;
use 5.008001;
use base qw( FFI::Build::File::C );
use constant default_suffix => '.f';
use constant default_encoding => ':utf8';

# ABSTRACT: Class to track Fortran source file in FFI::Build
# VERSION

sub accept_suffix
{
  (qr/\.f(90|95)?$/)
}

sub cc
{
  my($self) = @_;
  $self->platform->for;
}

1;
