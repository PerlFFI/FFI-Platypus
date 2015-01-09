# FIXME
use feature 'say';

use strict;
use warnings;

use FFI::Raw;

my $libuuid = 'libuuid.so.1';

my $uuid_generate = FFI::Raw -> new(
	$libuuid, 'uuid_generate',
	FFI::Raw::void, FFI::Raw::ptr
);

my $uuid_unparse = FFI::Raw -> new(
	$libuuid, 'uuid_unparse', FFI::Raw::void,
	FFI::Raw::ptr, FFI::Raw::ptr);

my $uuid = FFI::Raw::memptr(16); # 16 is sizeof(uuid_t)
my $str  = FFI::Raw::memptr(37); # 37 is the size of an UUID string

$uuid_generate -> call($uuid);
$uuid_unparse  -> call($uuid, $str);

say $str -> tostr;
