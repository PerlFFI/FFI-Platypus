package FFI::Platypus;

use strict;
use warnings;
use Exporter::Tidy
  default => [ qw( ffi_type ffi_signature ) ];

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
  
  if($language eq 'none')
  {
    $type = _ffi_type('none', $name, $name);
  }
  elsif($language eq 'c')
  {
    die "TODO";
  }
  else
  {
    die "no such language: $language";
  }
  
  wantarray ? ($type, @_) : $type;
}

1;
