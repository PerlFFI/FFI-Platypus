use strict;
use warnings;
use FFI::Platypus::Declare qw( string );

lib './libstring.so';
attach hello_rust => [] => 'string';

print hello_rust();
