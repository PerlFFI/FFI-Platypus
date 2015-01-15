package FFI::Platypus::Declare;

use strict;
use warnings;
use FFI::Platypus;

# ABSTRACT: Declarative interface to FFI::Platypus
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus::Declare 'string', 'int';

 lib undef; # use libc
 function puts => [string] => int;
 
 puts("hello world");

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

=head2 custom_type

 custom_type 'uint8' => 'my_custom_type', { ... };

Declare the given custom type.

=cut

sub custom_type ($$$)
{
  _ffi_object->custom_type(@_);
}

=head2 type_meta

 my $meta = type_meta 'int';

Get the type meta data for the given type.

=cut

sub type_meta($)
{
  _ffi_object->type_meta(@_);
}

=head2 function

 function 'my_function', ['uint8'] => 'string';
 function ['my_c_function_name' => 'my_perl_function_name'], ['uint8'] => 'string';

Attach the given function with argument and return types.  You can use a two element
array reference to install the function with a different name in perl space.

=cut

sub function ($$$;$)
{
  my($caller, $filename, $line) = caller;
  my($name, $args, $ret, $proto) = @_;
  my($symbol_name, $perl_name) = ref $name ? (@$name) : ($name, $name);
  my $function = _ffi_object->function($symbol_name, $args, $ret);
  $function->attach(join('::', $caller, $perl_name), "$filename:$line", $proto);
}

=head2 closure

 my $closure = closure { ... };

Create a closure that can be passed into a C function.

=cut

sub closure (&)
{
  my($coderef) = @_;
  FFI::Platypus::Closure->new($coderef);
}

=head2 sticky

 my $closure = sticky closure { ... }

Keyword to indicate the closure should not be deallocated for the life of the current process.

If you pass a closure into a C function without saving a reference to it like this:

 foo(closure { ... });

Perl will not see any references to it and try to free it immediately.  (this has to do with
the way Perl and C handle responsibilities for memory allocation differently).  One fix for 
this is to make sure the closure remains in scope using either C<my> or C<our>.  If you
know the closure will need to remain in existence for the life of the process (or if you do
not care about leaking memory), then you can add the sticky keyword to tell L<FFI::Platypus>
to keep the thing in memory.

 foo(sticky closure { ... });

=cut

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
  *{join '::', $caller, 'lib'} = \&lib;
  *{join '::', $caller, 'type'} = \&type;
  *{join '::', $caller, 'type_meta'} = \&type_meta;
  *{join '::', $caller, 'custom_type'} = \&custom_type;
  *{join '::', $caller, 'function'} = \&function;
  *{join '::', $caller, 'closure'} = \&closure;
  *{join '::', $caller, 'sticky'} = \&sticky;
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

Object oriented interface to platypus.

=item L<FFI::Platypus::Type>

Type definitions for L<FFI::Platypus>.

=item L<FFI::Platypus::Memory>

memory functions for FFI.

=item L<FFI::CheckLib>

Find dynamic libraries in a portable way.

=item L<FFI::TinyCC>

JIT compiler for FFI.

=item L<FFI::Raw>

Alternate interface to libffi with fewer features.  It notably lacks the ability to
create real xsubs, which may make L<FFI::Platypus> much faster.

=back

=cut
