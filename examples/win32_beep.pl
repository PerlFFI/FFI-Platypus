use strict;
use warnings;
use FFI::Platypus 1.00;

my($freq, $duration) = @_;
$freq     ||= 750;
$duration ||= 300;

FFI::Platypus
  ->new(lib=>[undef], lang => 'Win32')
  ->function( Beep => ['DWORD','DWORD']=>'BOOL')
  ->call($freq, $duration);
