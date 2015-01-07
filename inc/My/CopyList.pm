package inc::My::CopyList;

use strict;
use warnings;

our @list = map { [split /\// ] } qw(
  include/ppport.h
);

1;
