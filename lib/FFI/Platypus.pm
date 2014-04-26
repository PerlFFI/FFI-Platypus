package FFI::Platypus;

use strict;
use warnings;
use Carp qw( croak );
use Exporter::Tidy
  default => [ qw( ffi_type ffi_signature ffi_lib ffi_sub ) ];

BEGIN {

# ABSTRACT: Kinda like gluing a duckbill to an adorable mammal
# VERSION

  require XSLoader;
  XSLoader::load('FFI::Platypus', $VERSION);

}

our %_meta;

sub ffi_type ($$@)
{
  my($language, $name) = (shift, shift);
  
  my $type;
  
  if($language =~ /^(none|c)$/)
  {
    $type = _ffi_type($language, $name);
  }
  else
  {
    die "no such language: $language";
  }
  
  wantarray ? ($type, @_) : $type;
}

my $default_lib;

sub ffi_sub ($$$)
{
  my($lib, $name, $sig) = @_;
  my($lib_name, $perl_name) = ref($name) eq 'ARRAY' ? (@$name) : ($name, $name);
  my $package = caller;
  $perl_name = join '::', $package, $perl_name
    unless $perl_name =~ /::/;

  if(ref($lib) eq 'ARRAY')
  {
    if(@$lib == 0)
    {
      $lib = $default_lib ||= ffi_lib undef;
    }
    else
    {
      for(@$lib)
      {
        if($_->has_symbol($lib_name))
        {
          $lib = $_;
          last;
        }
      }
      croak "$lib_name not found in list of lib"
        if ref($lib) eq 'ARRAY';
    }
  }
  
  if(ref($sig) eq 'ARRAY')
  {
    # todo: recognize duplicate signatures
    # and reuse them
    $sig = ffi_signature @$sig;
  }

  return _ffi_sub($lib, $lib_name, $perl_name, $sig);
}

1;

=head1 ENVIRONMENT VARIABLES

The following is a (probably incomplete) list of environment variables
recognized by L<FFI::Platypus>:

=over 4

=item C<FFI_PLATYPUS_BUILD_VERBOSE>

Be more verbose to stdout during the configuration / build step.  All
of this verbosity may be viewed in the C<build.log>, but you may want
to see it spew as it happens.

=item C<FFI_PLATYPUS_TEST_LIBARCHIVE>

Full path to C<libarchive.so> or C<archive.dll> used optionally during test.

=back

=head1 BUNDLED SOFTWARE

This distribution comes with this bundled software:

=over 4

=item L<PkgConfig>

Currently maintained by Graham Ollis E<lt>plicease@cpan.orgE<gt>.
This is only used during the build process and only if the C<Build.PL>
cannot find libffi either by guessing or by using the system pkg-config.

Copyright 2012 M. Nunberg

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=back

=cut

