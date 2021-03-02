use strict;
use warnings;
use FFI::Platypus 1.00;

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib(undef);
$ffi->attach(puts => ['string'] => 'int');
$ffi->attach(strlen => ['string'] => 'int');

puts(strlen('somestring'));

$ffi->attach(strstr => ['string','string'] => 'string');

puts(strstr('somestring', 'string'));

#attach puts => [string] => int;

puts(puts("lol"));

$ffi->attach(strerror => ['int'] => 'string');

puts(strerror(2));
