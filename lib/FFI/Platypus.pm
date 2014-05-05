package FFI::Platypus;

use strict;
use warnings;
use Carp qw( croak );
use Exporter::Tidy
  default => [ qw( ffi_type ffi_signature ffi_lib ffi_sub ffi_closure ffi_meta ) ];

BEGIN {

# ABSTRACT: Kinda like gluing a duckbill to an adorable mammal
# VERSION

  require XSLoader;
  XSLoader::load('FFI::Platypus', $VERSION);

}

sub ffi_meta ($)
{
  ref($_[0]) eq 'CODE' ? _ffi_meta($_[0]) : $_[0];
}

sub ffi_type ($$@)
{
  my($language, $name) = (shift, shift);
  
  my $type;
  
  if($language =~ /^(ffi|c)$/)
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
my $anon_counter = 0;

sub ffi_sub ($$$)
{
  my($lib, $name, $sig) = @_;
  my($lib_name, $perl_name) = ref($name) eq 'ARRAY' ? (@$name) : ($name, $name);
  
  if(!defined $perl_name)
  {
    $perl_name = sprintf "FFI::Platypus::_anon_f%03d", $anon_counter++;
  }
  elsif($perl_name !~ /::/)
  {
    my $package = caller;
    $perl_name = join '::', $package, $perl_name;
  }

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

=item C<FFI_PLATYPUS_BUILD_ALLOCA>

L<FFI::Platypus> may use the non standard and sometimes controversial C<alloca>
function to allocate very small amounts of memory during ffi calls.  I
test whether or not it works on your platform during build, and use it in
moderation, so I believe it to be safe.  You may turn it off by setting
this environment variable to C<0> when you run C<Build.PL>.

=item C<FFI_PLATYPUS_BUILD_CFLAGS>

Extra c flags to include during the build of L<FFI::Platypus>.  Useful for
including debug flags like C<-g3>.

=item C<FFI_PLATYPUS_BUILD_LDFLAGS>

Extra linker flags to include during the build of L<FFI::Platypus>.

=item C<FFI_PLATYPUS_BUILD_REMOVE_OPT>

If true then L<FFI::Platypus> will attempt to remove optimization c flags
during the build step.  Normally the same flags used in building Perl
are used by default.  This option may be helpful when debugging the XS code,
but it is also quite simplistic and may break in some environments.

=item C<FFI_PLATYPUS_BUILD_SYSTEM_FFI>

If your system does not provide C<libffi>, then L<FFI::Platypus> will attempt
to build it from bundled source.  Setting this environment variable to C<0>
will skip the check for a system C<libffi> and build it from source regardless.

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

=item L<libffi>

If your system provides a version of C<libffi> that can be guessed or
discovered using C<pkg-config> or L<PkgConfig>, then it will be used.

If not, then a bundled version of libffi will be used.

 libffi - Copyright (c) 1996-2014  Anthony Green, Red Hat, Inc and others.
 See source files for details.
 
 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files (the
 ``Software''), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=item L<PkgConfig>

Currently maintained by Graham Ollis E<lt>plicease@cpan.orgE<gt>.
This is only used during the build process and only if the C<Build.PL>
cannot find libffi either by guessing or by using the system pkg-config.

Copyright 2012 M. Nunberg

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=back

=cut

