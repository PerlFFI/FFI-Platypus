#!/usr/bin/env perl

use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new( api => 2, lib => './add.so' );
$ffi->attach( add => ['int', 'int'] => 'int' );

print add(1,2), "\n";  # prints 3
