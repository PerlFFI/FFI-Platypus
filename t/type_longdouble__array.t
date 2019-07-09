use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Platypus::TypeParser;
use FFI::CheckLib;
use Config;

BEGIN {
  plan skip_all => 'test requires support for long double'
    unless FFI::Platypus::TypeParser->have_type('longdouble');
#  plan skip_all => 'test doesn\'t make sense on Perl with longdouble'
#    if $Config{uselongdouble};
}

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib lib => 'test', libpath => 't/ffi');

subtest 'Math::LongDouble is loaded when needed for return type' => sub {
  $ffi->function( 0 => ['longdouble'] => 'int');
  $ffi->function( 0 => ['int'] => 'int');

  is($INC{'Math/LongDouble.pm'}, undef, 'not pre-loaded');
  $ffi->function( 0 => ['longdouble[]'] => 'int' );

  my $pm = $INC{'Math/LongDouble.pm'};

  if(eval q{ use Math::LongDouble; 1 })
  {
    is($pm, $INC{'Math/LongDouble.pm'});
    isnt $pm, undef;
  }
  else
  {
    is($pm, undef);
    is($INC{'Math/LongDouble.pm'}, undef);
  }
};

done_testing;
