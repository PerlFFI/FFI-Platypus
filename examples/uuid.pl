use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus::Declare qw( void opaque string );
use FFI::Platypus::Memory qw( malloc free );

lib find_lib_or_exit lib => 'uuid';

attach uuid_generate => [opaque] => void;
attach uuid_unparse  => [opaque,opaque] => void;

my $uuid = malloc sizeof 'char[16]';  # uuid_t
uuid_generate($uuid);

my $string_opaque = malloc 37;       # 36 bytes to store a UUID string
uuid_unparse($uuid, $string_opaque);

print cast( opaque => string, $string_opaque), "\n";
