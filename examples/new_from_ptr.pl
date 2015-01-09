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
