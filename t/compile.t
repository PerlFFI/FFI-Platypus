use strict;
use warnings;
use Test::More tests => 1;
#use FFI::Platypus;

sub lib  ($);
sub type ($;$);
sub func ($$;$);

sub ffi (&)
{
  my($code) = @_;
  local *lib  = sub ($) { };
  local *type = sub ($;$) { };
  local *func = sub ($$;$) { };
  $code->();
}

ffi {
  lib '/lib/libfoo.so';
  type 'int';
  type 'const char *' => 'str';
  func 'puts', ['str'], 'int';
};

pass 'okay';
