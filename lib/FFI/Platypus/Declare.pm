package FFI::Platypus::Declare;

use strict;
use warnings;
use FFI::Platypus;
use base qw( Exporter );

our @EXPORT = qw( ffi lib type function );

our $ffi;

sub _ffi_object
{
  my $caller = caller(1);
  $ffi->{$caller} ||= FFI::Platypus->new;
}

sub ffi (&)
{
  my $caller = caller;
  local $ffi->{$caller} = FFI::Platypus->new;
  $_[0]->();
}

sub lib (@)
{
  _ffi_object->lib(@_);
}

sub type ($;$)
{
  _ffi_object->type(@_);
}

sub function ($$$)
{
  my $caller = caller;
  my($name, $args, $ret) = @_;
  my($symbol_name, $perl_name) = ref $name ? (@$name) : ($name, $name);
  my $function = _ffi_object->function($symbol_name, $args, $ret);
  no strict 'refs';
  *{join '::', $caller, $perl_name} = sub { $function->call(@_) };
}

1;
