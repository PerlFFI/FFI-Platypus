use strict;
use warnings;
use FFI::Platypus::Declare qw( int string );

lib undef;
function puts => [string] => int;
function atoi => [string] => int;

puts(atoi('56'));
