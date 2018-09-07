package FFI::Platypus::Internal;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus;
use base qw( Exporter );

require FFI::Platypus;
_init();

our @EXPORT = grep /^FFI_PL/, keys %FFI::Platypus::Internal::;

# ABSTRACT: For internal use only
# VERSION

=head1 SYNOPSIS

 perldoc FFI::Platypus

=head1 DESCRIPTION

This module is for internal use only.  Do not rely on it having any particular behavior, or even existing in future versions.
You have been warned.

=cut

1;
