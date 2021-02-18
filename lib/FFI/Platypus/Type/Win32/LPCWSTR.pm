package FFI::Platypus::Type::Win32::LPCWSTR;

use strict;
use warnings;
use 5.008004;
use FFI::Platypus;
use FFI::Platypus::Memory qw( strlenW );
use Encode qw( decode encode );

# ABSTRACT: Platypus custom type for Windows Unicode strings
# VERSION

=head1 SYNOPSIS

 use FFI::Platypus;

 my $ffi = FFI::Platypus->new( api => 1 );
 $ffi->lang('Win32');

 use constant MB_OK => 0;

 $ffi->attach([MessageBoxW => 'MessageBox'] => ['HWND', 'LPCWSTR', 'LPCWSTR', 'UINT'] => 'int');

 MessageBox(undef, "I ❤️ Platypus", "Confession", MB_OK);

=head1 DESCRIPTION

This module provides a L<FFI::Platypus> custom type for Windows Unicode strings.
The created LPCWSTR will be NULL-terminated.

This type can also be used as a return value. Returned LPCWSTR are expected
to be NULL-terminated, and they won't be freed.

This type is automatically loaded by C<< $ffi->lang('Win32'); >>.

=cut

use constant _incantation =>
  $^O eq 'MSWin32' && do { require Config; $Config::Config{archname} =~ /MSWin32-x64/ }
  ? 'Q'
  : 'L!';

my @stack;  # To keep buffer alive.

sub perl_to_native
{
  if(defined $_[0])
  {
    my $buf = encode('UTF-16le', $_[0]."\0");
    push @stack, \$buf;
    return unpack(_incantation, pack 'P', $buf);
  }
  else
  {
    push @stack, undef;
    return undef;
  }
}

sub perl_to_native_post
{
  pop @stack;
}

sub native_to_perl
{
   return unless defined $_[0];
   return decode('UTF-16le', unpack('P'.(strlenW($_[0])*2), pack(_incantation, $_[0])));
}

sub ffi_custom_type_api_1
{
  {
     native_type         => 'opaque',
     perl_to_native      => \&perl_to_native,
     perl_to_native_post => \&perl_to_native_post,
     native_to_perl      => \&native_to_perl,
  }
}

1;

=head1 SUPPORT

If something does not work the way you think it should, or if you have a
feature request, please open an issue on this project's GitHub Issue
tracker:

L<https://github.com/plicease/FFI-Platypus/issues>

=head1 CONTRIBUTING

If you have implemented a new feature or fixed a bug then you may make a
pull request on this project's GitHub repository:

L<https://github.com/plicease/FFI-Platypus/pulls>

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

=item L<FFI::Platypus::Lang::Win32>

=back

=cut
