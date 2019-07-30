use strict;
use warnings;
use Test::More;
use FFI::Platypus;

plan skip_all => 'TODO';

subtest 'only load as needed' => sub {

  my @warnings;
  local $SIG{__WARN__} = sub {
    note "[warning]\n", $_[0];
    push @warnings, $_[0];
  };

  my $ffi = FFI::Platypus->new( api => 1 );

  ok( !  FFI::Platypus->can('_bundle') );

  $ffi->bundle;

  ok( !! FFI::Platypus->can('_bundle') );
  
};

done_testing;
