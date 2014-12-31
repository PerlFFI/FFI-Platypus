package inc::My::CopyList;

use strict;
use warnings;

our @list = map { [split /\// ] } qw(
  xs/ppport.h
);

1;
