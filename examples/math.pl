use strict;
use warnings;
use FFI::Platypus::Declare qw( string int double );
use FFI::CheckLib;

lib undef;
attach puts => [string] => int;
attach fdim => [double,double] => double;

puts(fdim(7.0, 2.0));

attach cos => [double] => double;

puts(cos(2.0));

attach fmax => [double, double] => double;

puts(fmax(2.0,3.0));
