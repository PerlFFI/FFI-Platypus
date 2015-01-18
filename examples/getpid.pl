use strict;
use warnings;
use FFI::Platypus::Declare qw( string int );

lib undef;
attach puts => [string] => int;
attach getpid => [] => int;

puts(getpid());
