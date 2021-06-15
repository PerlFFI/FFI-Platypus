use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::Platypus::TypeParser;

subtest 'basic' => sub {

  my $tp = FFI::Platypus::TypeParser->new;
  isa_ok $tp, 'FFI::Platypus::TypeParser';

};

subtest 'pick the right one' => sub {

  isa_ok(
    FFI::Platypus->new( api => 0 )->{tp},
    'FFI::Platypus::TypeParser::Version0',
  );

  # ignore api=1 warning
  local $SIG{__WARN__} = sub { note "[warnings]\n", $_[0] };

  isa_ok(
    FFI::Platypus->new( api => 1 )->{tp},
    'FFI::Platypus::TypeParser::Version1',
  );

};

done_testing;
