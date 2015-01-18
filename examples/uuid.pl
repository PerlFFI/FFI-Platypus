use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus::Declare qw( void pointer string );
use FFI::Platypus::Memory qw( malloc free );

lib find_lib_or_exit lib => 'uuid';

attach uuid_generate => [pointer] => void;
attach uuid_unparse  => [pointer,pointer] => void;

my $uuid = malloc sizeof 'char[16]';  # uuid_t
uuid_generate($uuid);

my $string_pointer = malloc 37;       # 36 bytes to store a UUID string
uuid_unparse($uuid, $string_pointer);

print cast( pointer => string, $string_pointer), "\n";
