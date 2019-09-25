use strict;
use warnings;
use FFI::Platypus;

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib(undef);
$ffi->attach([pipe=>'mypipe'] => ['int[2]'] => 'int');

my @fd = (0,0);
mypipe(\@fd);
my($fd1,$fd2) = @fd;

print "$fd1 $fd2\n";
