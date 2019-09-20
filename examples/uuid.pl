use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus;
use FFI::Platypus::Memory qw( malloc free );

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lib(find_lib_or_exit lib => 'uuid');
$ffi->type('string(37)*' => 'uuid_string');
$ffi->type('record(16)*' => 'uuid_t');

$ffi->attach(uuid_generate => ['uuid_t'] => 'void');
$ffi->attach(uuid_unparse  => ['uuid_t','uuid_string'] => 'void');

my $uuid = "\0" x 16;  # uuid_t
uuid_generate($uuid);

my $string = "\0" x 37; # 36 bytes to store a UUID string
                        # + NUL termination
uuid_unparse($uuid, $string);

print "$string\n";
