package FFI::Build::File::CXX;

use strict;
use warnings;
use 5.008001;
use base qw( FFI::Build::File::C );
use constant default_suffix => '.cxx';
use constant default_encoding => ':utf8';

# ABSTRACT: Class to track C source file in FFI::Build
# VERSION

=head1 SYNOPSIS

 use FFI::Build::File::CXX;
 
 my $c = FFI::Build::File::CXX->new('src/foo.cxx');

=head1 DESCRIPTION

File class for C++ source files.

=cut

sub accept_suffix
{
  (qr/\.c(xx|pp)$/)
}

sub cc
{
  my($self) = @_;
  $self->platform->cxx;
}

sub ld
{
  my($self) = @_;
  $self->platform->cxx;
}

1;
