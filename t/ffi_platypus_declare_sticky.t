use strict;
use warnings;
use Test::More tests => 1;
use FFI::CheckLib;
use FFI::Platypus::Declare
  qw( uint8 void ),
  ['(uint8)->uint8' => 'closure_t'];

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

attach [uint8_set_closure => 'set_closure']   => [closure_t] => void;
attach [uint8_call_closure => 'call_closure'] => [uint8] => uint8;

set_closure(sticky closure { $_[0] * 2 });
is call_closure(2), 4, 'call_closure(2) = 4';
