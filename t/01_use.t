use strict;
use warnings;
use Test::More;

require_ok 'App::fbx';
require_ok 'FFI::Build';
require_ok 'FFI::Build::MM';
require_ok 'FFI::Build::Platform';
require_ok 'FFI::Build::File::Base';
require_ok 'FFI::Build::File::C';
require_ok 'FFI::Build::File::CXX';
require_ok 'FFI::Build::File::Fortran';
require_ok 'FFI::Build::File::Object';
require_ok 'FFI::Build::File::Library';

done_testing;
