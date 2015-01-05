package FFI::Platypus::Declare;

use strict;
use warnings;
use FFI::Platypus;

# ABSTRACT: Declarative interface to FFI::Platypus
# VERSION

=head1 SYNOPSIS

 use FFI::CheckLib;
 use FFI::Platypus::Declare
   [ uint8 => 'u8' ],
   'string';
 
 lib find_lib lib => 'mylib', symbol => 'my_function';
 function my_function => [ u8 ] => 'string';

=head1 DESCRIPTION

This module provides a declarative interface to L<FFI::Platypus>.
It provides a more concise interface at the cost of a little less
power, and a little more namespace pollution.

=cut

our $ffi    = {};
our $types  = {};

sub _ffi_object
{
  my $caller = caller(1);
  $ffi->{$caller} ||= FFI::Platypus->new;
}

=head1 FUNCTIONS

=head2 ffi

=cut

sub ffi (&)
{
  my $caller = caller;
  local $ffi->{$caller} = FFI::Platypus->new;
  $_[0]->();
}

=head2 lib

 lib '/lib/libfoo.so';

Specify one or more dynamic libraries to search for symbols.
If you are unsure of the location / version of the library then
you can use L<FFI::CheckLib#find_lib>.

=cut

sub lib (@)
{
  _ffi_object->lib(@_);
}

=head2 type

 type 'uint8' => 'my_unsigned_int_8';

Declare the given type.

=cut

sub type ($;$)
{
  _ffi_object->type(@_);
}

=head2 function

 function 'my_function', ['uint8'] => 'string';
 function ['my_c_function_name' => 'my_perl_function_name'], ['uint8'] => 'string';

Attach the given function with argument and return types.  You can use a two element
array reference to install the function with a different name in perl space.

=cut

sub function ($$$)
{
  my $caller = caller;
  my($name, $args, $ret) = @_;
  my($symbol_name, $perl_name) = ref $name ? (@$name) : ($name, $name);
  my $function = _ffi_object->function($symbol_name, $args, $ret);
  no strict 'refs';
  *{join '::', $caller, $perl_name} = sub { $function->call(@_) };
}

sub import
{
  my $caller = caller;
  shift; # class
  
  foreach my $arg (@_)
  {
    if(ref $arg)
    {
      _ffi_object->type(@$arg);
      no strict 'refs';
      *{join '::', $caller, $arg->[1]} = sub () { $arg->[0] };
    }
    else
    {
      _ffi_object->type($arg);
      no strict 'refs';
      *{join '::', $caller, $arg} = sub () { $arg };
    }
  }
  
  no strict 'refs';
  *{join '::', $caller, 'ffi'} = \&ffi;
  *{join '::', $caller, 'lib'} = \&lib;
  *{join '::', $caller, 'type'} = \&type;
  *{join '::', $caller, 'function'} = \&function;
}

1;
