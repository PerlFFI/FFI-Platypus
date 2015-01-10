use strict;
use warnings;
use FFI::Platypus::Declare qw( string int );

lib undef;
function puts => [string] => int;
function getpid => [] => int;

puts(getpid());
