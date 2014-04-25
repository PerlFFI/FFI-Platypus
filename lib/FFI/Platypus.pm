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
