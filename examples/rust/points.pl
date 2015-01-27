use strict;
use warnings;
use FFI::Platypus::Declare
  [ sint32 => 'i32' ],
  [ double => 'f64' ],
  [ opaque => 'Point' ];

lib './libpoints.so';
attach make_point => [ i32, i32 ] => Point;
attach get_distance => [Point, Point] => f64;

print get_distance(make_point(2,2), make_point(4,4)), "\n";

# borrowed with modifications from:
# http://paul.woolcock.us/posts/rust-perl-julia-ffi.html
# http://blog.skylight.io/bending-the-curve-writing-safe-fast-native-gems-with-rust/

