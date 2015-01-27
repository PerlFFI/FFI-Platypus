#![feature(box_syntax)]

// compile with: rustc --crate-type dylib points.rs
// borrowed with modifications from:
// http://paul.woolcock.us/posts/rust-perl-julia-ffi.html
// http://blog.skylight.io/bending-the-curve-writing-safe-fast-native-gems-with-rust/

use std::num::{Int,Float};

#[deriving(Copy)]
pub struct Point { x: i32, y: i32 }

struct Line { p1: Point, p2: Point }

impl Line {
  pub fn length(&self) -> f64 {
  
    let xdiff = self.p1.x - self.p2.x;
    let ydiff = self.p1.y - self.p2.y;
    
    ((xdiff.pow(2) + ydiff.pow(2)) as f64).sqrt()
  
  }
}

#[no_mangle]
pub extern "C" fn make_point(x: i32, y:i32) -> Box<Point> {
  box Point { x: x, y: y }
}

#[no_mangle]
pub extern "C" fn get_distance(p1: &Point, p2: &Point) -> f64 {
  Line { p1: Point { x: p1.x, y: p1.y }, p2: Point { x: p2.x, y: p2.y } }.length()
}

