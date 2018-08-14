use strict;
use warnings;
use Test::More;
use FFI::Platypus::ShareConfig;
use Data::Dumper;

sub xdump ($)
{
  my($object) = @_;
  note(Data::Dumper->new([$object])->Indent(2)->Terse(1)->Sortkeys(1)->Dump);
}

note(xdump(FFI::Platypus::ShareConfig->get));

is(ref(FFI::Platypus::ShareConfig->get), 'HASH');
is(FFI::Platypus::ShareConfig->get('test-key'), 'test-value');

done_testing;
