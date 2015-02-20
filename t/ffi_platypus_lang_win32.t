use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus::Lang::Win32;

my $map = FFI::Platypus::Lang::Win32->native_type_map;

foreach my $alias (sort keys %$map)
{
  my $type = $map->{$alias};
  note sprintf("%-30s %s", $alias, $type);
}

pass 'good';
