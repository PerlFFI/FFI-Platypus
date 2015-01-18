use strict;
use warnings;
use FFI::Platypus::Declare qw( int string );

lib undef;
attach puts => [string] => int;
attach atoi => [string] => int;

puts(atoi('56'));
