use strict;
use warnings;
use FFI::Platypus::Declare qw( string int double );
use FFI::CheckLib;

lib undef;
function puts => [string] => int;
function fdim => [double,double] => double;

puts(fdim(7.0, 2.0));

function cos => [double] => double;

puts(cos(2.0));

function fmax => [double, double] => double;

puts(fmax(2.0,3.0));

