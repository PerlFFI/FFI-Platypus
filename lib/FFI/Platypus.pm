package FFI::Platypus;

use strict;
use warnings;

# ABSTRACT: Kinda like gluing a duckbill to an adorable mammal
# VERSION

sub lib  ($)    {}
sub type ($;$)  {}
sub func ($$;$) {}

sub ffi (&)
{
  my($code)   = @_;
  my($caller) = caller;
  
  #my $lib  = sub ($)    { };
  #my $type = sub ($;$)  { };
  #my $func = sub ($$;$) { };
  #no strict 'refs';
  #local *{join '::', $caller, 'lib'}  = $lib;
  #local *{join '::', $caller, 'type'} = $type;
  #local *{join '::', $caller, 'func'} = $func;

  eval qq {
    package $caller;
    local *lib  = sub (\$) {};
    local *type = sub (\$;\$) { };
    local *func = sub (\$\$;\$) { };
    \$caller->();
  };
  die $@ if $@;
}

sub import
{
  my($caller) = caller;
  eval qq{
    package $caller;
    sub lib  (\$);
    sub type (\$;\$);
    sub func (\$\$;\$);
  };
  die $@ if $@;
}

1;
