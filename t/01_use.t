use strict;
use warnings;
use Test::More;

require_ok 'FFI::Build';
require_ok 'FFI::Build::Platform';
require_ok 'FFI::Build::File::Base';
require_ok 'FFI::Build::File::C';
require_ok 'FFI::Build::File::CXX';
require_ok 'FFI::Build::File::Object';
require_ok 'FFI::Build::File::Library';
require_ok 'FFI::Build::Library';

done_testing;
