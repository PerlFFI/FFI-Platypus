package FFI::Build::File::Library;

use strict;
use warnings;
use 5.008001;
use base qw( FFI::Build::File::Base );
use Config ();
use constant default_suffix => $^O eq 'MSWin32' ? '.dll' : ".$Config::Config{dlext}";
use constant default_encoding => ':raw';

# ABSTRACT: Class to track object file in FFI::Build
# VERSION

1;
