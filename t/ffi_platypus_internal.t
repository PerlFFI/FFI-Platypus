use Test2::V0 -no_srand => 1;
use FFI::Platypus::Internal;

subtest 'basic' => sub {

  note "alpha order:";

  foreach my $const (sort @FFI::Platypus::Internal::EXPORT)
  {
    pass sprintf("%-30s 0x%04x", $const, __PACKAGE__->$const);
  }

  note "value order:";

  foreach my $const (sort { __PACKAGE__->$a <=> __PACKAGE__->$b } @FFI::Platypus::Internal::EXPORT)
  {
    pass sprintf("%-30s 0x%04x", $const, __PACKAGE__->$const);
  }

};

done_testing;
