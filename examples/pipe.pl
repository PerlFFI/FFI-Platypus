use strict;
use warnings;
use FFI::Platypus::Declare qw( int );

lib undef;
function [pipe=>'mypipe'] => ['int[2]'] => int;

my @fd = (0,0);
mypipe(\@fd);
my($fd1,$fd2) = @fd;

print "$fd1 $fd2\n";
