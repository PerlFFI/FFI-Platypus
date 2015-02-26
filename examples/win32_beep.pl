use strict;
use warnings;
use FFI::Platypus;

my($freq, $duration) = @_;
$freq     ||= 750;
$duration ||= 300;

FFI::Platypus
  ->new(lib=>[undef], lang => 'Win32')
  ->function( Beep => ['uint','uint']=>'bool')
  ->call($freq, $duration);
