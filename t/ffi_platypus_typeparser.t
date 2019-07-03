use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::Platypus::TypeParser;

subtest 'pick the right one' => sub {

  is(
    FFI::Platypus->new( api => 0 )->{type_parser},
    'FFI::Platypus::TypeParser::Version0',
    'api = 0',
  );

  # ignore api=1 warning
  local $SIG{__WARN__} = sub { note "[warnings]\n", $_[0] };

  is(
    FFI::Platypus->new( api => 1 )->{type_parser},
    'FFI::Platypus::TypeParser::Version1',
    'api = 1',
  );

};

done_testing;
