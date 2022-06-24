use strict;
use warnings;
use FFI::Platypus 2.00;

my($freq, $duration) = @_;
$freq     ||= 750;
$duration ||= 300;

FFI::Platypus
  ->new( api => 2, lib=>[undef], lang => 'Win32' )
  ->function( Beep => ['DWORD','DWORD']=>'BOOL')
  ->call($freq, $duration);
