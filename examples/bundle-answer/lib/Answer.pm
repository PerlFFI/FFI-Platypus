package Answer;

use strict;
use warnings;
use FFI::Platypus 1.00;
use base qw( Exporter );

our @EXPORT = qw( answer );

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->bundle;
$ffi->attach( answer => [] => 'int' );

1;
