package FFI::Platypus::Memory;

use strict;
use warnings;
use FFI::Platypus;
use base qw( Exporter );

# ABSTRACT: Memory functions for FFI
# VERSION

our @EXPORT = qw( malloc free calloc realloc memcpy memset sizeof cast strdup );

my $ffi = FFI::Platypus->new;
$ffi->lib(undef);
$ffi->type($_) foreach qw( opaque size_t void int );

$ffi->attach(malloc  => ['size_t']                     => 'opaque' => '$');
$ffi->attach(free    => ['opaque']                     => 'void'   => '$');
$ffi->attach(calloc  => ['size_t', 'size_t']           => 'opaque' => '$$');
$ffi->attach(realloc => ['opaque', 'size_t']           => 'opaque' => '$$');
$ffi->attach(memcpy  => ['opaque', 'opaque', 'size_t'] => 'opaque' => '$$$');
$ffi->attach(memset  => ['opaque', 'int', 'size_t']    => 'opaque' => '$$$');
$ffi->attach(strdup  => ['string']                     => 'opaque' => '$');

sub sizeof ($)
{
  $ffi->type($_[0]);
  $ffi->type_meta($_[0])->{size};
}

sub cast ($$$)
{
  my($type1, $type2, $value) = @_;
  $ffi->function(0 => [$type1] => $type2)->call($value);
}

1;
