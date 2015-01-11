use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus;

# The Declare interface does not allow creating functions
# from pointers, so we will use the OO interface instead.
my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib_or_exit lib => 'm');

my $address = $ffi->find_symbol('fmax'); # could also use DynaLoader or FFI::TinyCC

$ffi->attach([$address => 'fmax'] => ['double','double'] => 'double', '$$');

fmax(2.0,4.0);

__END__
# FIXME
use feature 'say';

use strict;
use warnings;

use FFI::Raw;
use DynaLoader;

my $lib = DynaLoader::dl_load_file(DynaLoader::dl_findfile('-lm'));
my $fun = DynaLoader::dl_find_symbol($lib, 'fmax');

my $fmax = FFI::Raw -> new_from_ptr(
	$fun, FFI::Raw::double,
	FFI::Raw::double, FFI::Raw::double
);

say $fmax -> call(2.0, 4.0);
