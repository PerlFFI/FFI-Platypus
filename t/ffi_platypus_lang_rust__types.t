use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus::Lang::Rust;

my $types = FFI::Platypus::Lang::Rust->native_type_map;

foreach my $rust_type (sort keys %$types)
{
  note sprintf "%-10s %s\n", $rust_type, $types->{$rust_type};
}

pass 'okay';
