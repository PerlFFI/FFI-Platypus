# FFI::Raw = libffi bindings for Perl
# written in XS
use strict;
use warnings;
use v5.10;
use FFI::Raw;

my $puts = FFI::Raw->new(
  'libc.so.6', 'puts', FFI::Raw::int, FFI::Raw::str,
);

$puts->call('hello there!');
