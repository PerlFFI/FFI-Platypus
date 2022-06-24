use strict;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib(undef);
$ffi->type('int' => 'character');

my @list = qw(
  alnum alpha ascii blank cntrl digit lower print punct
  space upper xdigit
);

$ffi->attach("is$_" => ['character'] => 'int') for @list;

my $char = shift(@ARGV) || 'a';

no strict 'refs';
printf "'%s' is %s %s\n", $char, $_, &{'is'.$_}(ord $char) for @list;
