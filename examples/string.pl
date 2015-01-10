use strict;
use warnings;
use FFI::Platypus::Declare qw( int string );

lib undef;
function puts => [string] => int;
function strlen => [string] => int;

puts(strlen('somestring'));

function strstr => [string,string] => string;

puts(strstr('somestring', 'string'));

#function puts => [string] => int;

puts(puts("lol"));

function strerror => [int] => string;

puts(strerror(2));
