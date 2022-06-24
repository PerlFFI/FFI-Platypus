use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new( api => 2 );

foreach my $type_name (sort $ffi->types)
{
  my $meta = $ffi->type_meta($type_name);
  next unless defined $meta->{element_type} && $meta->{element_type} eq 'int';
  printf "%20s %s\n", $type_name, $meta->{ffi_type};
}
