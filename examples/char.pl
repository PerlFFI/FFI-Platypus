use strict;
use warnings;
use FFI::Platypus::Declare
  'int',
  [int => 'character'];

lib undef;

my @list = qw( 
  alnum alpha ascii blank cntrl digit lower print punct 
  space upper xdigit
);

attach "is$_" => [character] => int for @list;

my $char = shift(@ARGV) || 'a';

no strict 'refs';
printf "'%s' is %s %s\n", $char, $_, &{'is'.$_}(ord $char) for @list;
