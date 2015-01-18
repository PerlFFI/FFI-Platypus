use strict;
use warnings;
use FFI::Platypus::Declare qw( int string );

lib undef;
attach puts => [string] => int;
attach strlen => [string] => int;

puts(strlen('somestring'));

attach strstr => [string,string] => string;

puts(strstr('somestring', 'string'));

#attach puts => [string] => int;

puts(puts("lol"));

attach strerror => [int] => string;

puts(strerror(2));
