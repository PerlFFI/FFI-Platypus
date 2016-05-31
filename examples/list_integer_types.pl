use strict;
use warnings;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;

foreach my $type_name (sort FFI::Platypus->types)
{
  my $meta = $ffi->type_meta($type_name);
  next unless $meta->{element_type} eq 'int';
  printf "%20s %s\n", $type_name, $meta->{ffi_type};
}
