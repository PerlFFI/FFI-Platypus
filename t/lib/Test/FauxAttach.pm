package Test::FauxAttach;

use strict;
use warnings;
use Test::More;

my @funcs;

# This plugin implements an alternative to attach/sub_ref
# without the process level-leak which makes it easier to
# find real leaks.  It relies on no attached sub being called
# in END, etc. blocks, which we cannot normally rely on.
# it's also probably a lot slower than a real xsub.

sub import
{
  die "load Test::FauxAttach before FFI::Platypus::Function"
    if $INC{'FFI/Platypus/Function.pm'};
  require FFI::Platypus::Function;

  *FFI::Platypus::Function::Function::_sub_ref = sub {
    my($self, $location) = @_;
    push @funcs, $self;
    my $i = $#funcs;
    sub { $funcs[$i]->call(@_) };
  };

  *FFI::Platypus::Function::Function::_attach = sub {
    my($self, $perl_name, $location, $proto) = @_;
    note "  attaching: $perl_name";
    my $xsub = $self->_sub_ref($location);
    FFI::Platypus::Function::Function::Wrapper::_set_prototype($xsub, $proto) if defined $proto;
    no strict 'refs';
    *{"$perl_name"} = $xsub;
  };
}

END {
  note "deleting @{[ scalar @funcs ]} attached functions";
  @funcs = ();
}

1;
