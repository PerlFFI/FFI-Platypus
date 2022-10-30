package FFI::Platypus::Lang;

use strict;
use warnings;
use 5.008004;

# ABSTRACT: Language specific customizations
# VERSION

=head1 SYNOPSIS

 perldoc FFI::Platypus::Lang;

=head1 DESCRIPTION

This namespace is reserved for language specific customizations of L<FFI::Platypus>.
This usually involves providing native type maps.  It can also involve computing
mangled names.  The default language is C, and is defined in L<FFI::Platypus::Lang::C>.

This package itself doesn't do anything, it serves only as documentation.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

Platypus itself.

=item L<FFI::Platypus::Lang::ASM>

This language plugin provides no type aliases, and is intended
for use with assembly language or for when no other language
plugin is appropriate.

=item L<FFI::Platypus::Lang::C>

Language plugin for the C programming language.

=item L<FFI::Platypus::Lang::Fortran>

Non-core language plugin for the Fortran programming language.

=item L<FFI::Platypus::Lang::CPP>

Non-core language plugin for the C++ programming language.

=item L<FFI::Platypus::Lang::Go>

Non-core language plugin for the Go programming language.

=item L<FFI::Platypus::Lang::Pascal>

Non-core language plugin for the Pascal programming language.

=item L<FFI::Platypus::Lang::Rust>

Non-core language plugin for the Rust programming language.

=item L<FFI::Platypus::Lang::Win32>

Language plugin for use with the Win32 API.

=item L<FFI::Platypus::Lang::Zig>

Non-core language plugin for the Zig programming language.

=back

=cut


1;
