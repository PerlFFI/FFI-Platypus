use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus 2.00;
use FFI::Platypus::Memory qw( malloc free );

my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib(find_lib_or_die lib => 'uuid');
$ffi->type('string(37)*' => 'uuid_string');
$ffi->type('record(16)*' => 'uuid_t');

$ffi->attach(uuid_generate => ['uuid_t'] => 'void');
$ffi->attach(uuid_unparse  => ['uuid_t','uuid_string'] => 'void');

my $uuid = "\0" x $ffi->sizeof('uuid_t');
uuid_generate($uuid);

my $string = "\0" x $ffi->sizeof('uuid_string');
uuid_unparse($uuid, $string);

print "$string\n";
