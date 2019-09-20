package FFI::Platypus::Type::StringArray;

use strict;
use warnings;
use FFI::Platypus;

# ABSTRACT: Platypus custom type for arrays of strings
# VERSION

=head1 SYNOPSIS

In your C code:

 void
 takes_string_array(const char **array)
 {
   ...
 }
 
 void
 takes_fixed_string_array(const char *array[5])
 {
   ...
 }

In your L<Platypus::FFI> code:

 use FFI::Platypus;
 
 my $ffi = FFI::Platypus->new( api => 1 );
 $ffi->load_custom_type('::StringArray' => 'string_array');
 $ffi->load_custom_type('::StringArray' => 'string_5' => 5);
 
 $ffi->attach(takes_string_array => ['string_array'] => 'void');
 $ffi->attach(takes_fixed_string_array => ['string_5'] => 'void');
 
 my @list = qw( foo bar baz );
 
 takes_string_array(\@list);
 takes_fixed_string_array([qw( s1 s2 s3 s4 s5 )]);

=head1 DESCRIPTION

B<NOTE>: The primary motivation for this custom type was originally to
fill the void left by the fact that L<FFI::Platypus> did not support arrays
of strings by itself.  Since 0.62 this support has been added, and that is
probably what you want to use, but the semantics and feature set are
slightly different, so there are cases where you might want to use this
custom type.

This module provides a L<FFI::Platypus> custom type for arrays of
strings. The array is always NULL terminated.  Return types are supported!

This custom type takes two optional arguments.  The first is the size of
arrays and the second is a default value to fill in any values that
aren't provided when the function is called.  If not default is provided
then C<NULL> will be passed in for those values.

=cut

use constant _incantation =>
  $^O eq 'MSWin32' && $Config::Config{archname} =~ /MSWin32-x64/
  ? 'Q'
  : 'L!';
use constant _size_of_pointer => FFI::Platypus->new( api => 1, experimental => 1 )->sizeof('opaque');
use constant _pointer_buffer => "P" . _size_of_pointer;

my @stack;

sub perl_to_native
{
  # this is the variable length version
  # and is actually simpler than the
  # fixed length version
  my $count = scalar @{ $_[0] };
  my $pointers = pack(('P' x $count)._incantation, @{ $_[0] }, 0);
  my $array_pointer = unpack _incantation, pack 'P', $pointers;
  push @stack, [ \$_[0], \$pointers ];
  $array_pointer;
}

sub perl_to_native_post
{
  pop @stack;
  ();
}

sub native_to_perl
{
  return unless defined $_[0];
  my @list;
  my $i=0;
  while(1)
  {
    my $pointer_pointer = unpack(
      _incantation,
      unpack(
        _pointer_buffer,
        pack(
          _incantation, $_[0]+_size_of_pointer*$i
        )
      )
    );
    last unless $pointer_pointer;
    push @list, unpack('p', pack(_incantation, $pointer_pointer));
    $i++;
  }
  \@list;
}

sub ffi_custom_type_api_1
{
  # arg0 = class
  # arg1 = FFI::Platypus instance
  # arg2 = array size
  # arg3 = default value
  my(undef, undef, $count, $default) = @_;

  my $config = {
    native_type => 'opaque',
    perl_to_native => \&perl_to_native,
    perl_to_native_post => \&perl_to_native_post,
    native_to_perl => \&native_to_perl,
  };

  if(defined $count)
  {
    my $end = $count-1;

    $config->{perl_to_native} = sub {
      my $incantation = '';

      my @list = ((map {
        defined $_
          ? do { $incantation .= 'P'; $_ }
          : defined $default
            ? do { $incantation .= 'P'; $default }
            : do { $incantation .= _incantation; 0 };
      } @{ $_[0] }[0..$end]), 0);

      $incantation .= _incantation;

      my $pointers = pack $incantation, @list;
      my $array_pointer = unpack _incantation, pack 'P', $pointers;
      push @stack, [ \@list, $pointers ];
      $array_pointer;
    };

    my $pointer_buffer = "P@{[ FFI::Platypus->new( api => 1, experimental => 1 )->sizeof('opaque') * $count ]}";
    my $incantation_count = _incantation.$count;

    $config->{native_to_perl} = sub {
      return unless defined $_[0];
      my @pointer_pointer = unpack($incantation_count, unpack($pointer_buffer, pack(_incantation, $_[0])));
      [map { $_ ? unpack('p', pack(_incantation, $_)) : $default } @pointer_pointer];
    };

  }

  $config;
}

1;

=head1 SUPPORT

If something does not work the way you think it should, or if you have a
feature request, please open an issue on this project's GitHub Issue
tracker:

L<https://github.com/plicease/FFI-Platypus-Type-StringArray/issues>

=head1 CONTRIBUTING

If you have implemented a new feature or fixed a bug then you may make a
pull request on this project's GitHub repository:

L<https://github.com/plicease/FFI-Platypus-Type-StringArray/pulls>

This project's GitHub issue tracker listed above is not Write-Only.  If
you want to contribute then feel free to browse through the existing
issues and see if there is something you feel you might be good at and
take a whack at the problem.  I frequently open issues myself that I
hope will be accomplished by someone in the future but do not have time
to immediately implement myself.

Another good area to help out in is documentation.  I try to make sure
that there is good document coverage, that is there should be
documentation describing all the public features and warnings about
common pitfalls, but an outsider's or alternate view point on such
things would be welcome; if you see something confusing or lacks
sufficient detail I encourage documentation only pull requests to
improve things.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

=item L<FFI::Platypus::Type::StringPointer>

=back

=cut

