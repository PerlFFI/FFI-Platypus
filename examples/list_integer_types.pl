use strict;
use warnings;
use FFI::Platypus::Declare;

foreach my $type_name (sort FFI::Platypus->types)
{
  my $meta = type_meta $type_name;
  next unless $meta->{element_type} eq 'int';
  printf "%20s %s\n", $type_name, $meta->{ffi_type};
}
