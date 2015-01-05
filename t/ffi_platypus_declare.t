use strict;
use warnings;
use Test::More tests => 2;
use FFI::CheckLib;
use FFI::Platypus::Declare;
use constant uint8 => 'uint8';

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';
function 'f0', [uint8] => uint8;
function [f0 => 'f1'], [uint8] => uint8;

is f0(22), 22, 'f0(22) = 22';  
is f1(22), 22, 'f1(22) = 22';
