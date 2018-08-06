package FFI::Build::File::Object;

use strict;
use warnings;
use 5.008001;
use base qw( FFI::Build::File::Base );
use FFI::Build::Platform;
use constant default_suffix => FFI::Build::Platform->object_suffix;
use constant default_encoding => ':raw';

# ABSTRACT: Class to track object file in FFI::Build
# VERSION

1;
