use strict;
use warnings;
use Test::More;
BEGIN { plan skip_all => 'Requires a threading Perl or forks' unless eval q{ use threads; 1 } }
use FFI::CheckLib;
use FFI::Platypus::Declare qw( uint8 );

plan tests => 2;

lib find_lib lib => 'test', symbol => 'f0', libpath => 'libtest';

attach f0 => [uint8] => uint8;

is(threads->create(sub { f0(22) })->join(), 22, 'works in a thread');

is f0(24), 24, 'works in main thread';
