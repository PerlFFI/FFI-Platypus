use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib;
use Data::Dumper ();

{ package FFI::Platypus::Lang::Go;

  sub native_type_map
  {
    { 'gostring' => '@go_string' }
  }

  $INC{'FFI/Platypus/Lang/Go.pm'} = __FILE__;

}

sub xdump ($)
{
  my($object) = @_;
  note(Data::Dumper->new([$object])->Indent(0)->Terse(1)->Sortkeys(1)->Dump);
}
    

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi');
$ffi->lang('Go');

xdump($ffi->type_meta('gostring'));

is($ffi->sizeof('gostring'), $ffi->sizeof('opaque') * 2);

is($ffi->function(go_null_string => [] => 'gostring')->call, '');
is($ffi->function(go_some_string => [] => 'gostring')->call, "some\0string");

done_testing;
