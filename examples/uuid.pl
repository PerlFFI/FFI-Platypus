use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'void',
  [ 'string(37)' => 'uuid_string' ],
  [ 'record(16)' => 'uuid_t' ];
use FFI::Platypus::Memory qw( malloc free );

lib find_lib_or_exit lib => 'uuid';

attach uuid_generate => [uuid_t] => void;
attach uuid_unparse  => [uuid_t,uuid_string] => void;

my $uuid = "\0" x 16;  # uuid_t
uuid_generate($uuid);

my $string = "\0" x 37; # 36 bytes to store a UUID string 
                        # + NUL termination
uuid_unparse($uuid, $string);

print "$string\n";
