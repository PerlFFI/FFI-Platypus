use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus;

subtest 'class or instance method' => sub {
  plan tests => 1;

  my @class = FFI::Platypus->types;
  my @instance = FFI::Platypus->new->types;
  
  is_deeply \@class, \@instance, 'class and instance methods are identical';

  note "type: $_" foreach sort @class;

};
