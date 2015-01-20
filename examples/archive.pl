use strict;
use warnings;
use FFI::Platypus      ();
use FFI::Platypus::API ();
use FFI::CheckLib      ();

# This example uses FreeBSD's libarchive to list the contents of any
# archive format that it suppors.  We've also filled out a part of
# the ArchiveWrite class that could be used for writing archive formats
# supported by libarchive

my $ffi = FFI::Platypus->new;
$ffi->lib(FFI::CheckLib::find_lib_or_exit lib => 'archive');

$ffi->custom_type(archive => {
  native_type    => 'opaque',
  perl_to_native => sub { ${$_[0]} },
  native_to_perl => sub {
    # this works because archive_read_new ignores any arguments
    # and we pass in the class name which we can get here.
    my $class = FFI::Platypus::API::arguments_get_string(0);
    bless \$_[0], $class;
  },
});

$ffi->custom_type(archive_entry => {
  native_type => 'opaque',
  perl_to_native => sub { ${$_[0]} },
  native_to_perl => sub {
    # works likewise for archive_entry objects
    my $class = FFI::Platypus::API::arguments_get_string(0);
    bless \$_[0], $class,
  },
});

package Archive;

# base class is "abstract" having no constructor or destructor

$ffi->attach( [ archive_error_string => 'error_string' ] => ['archive'] => 'string' );

package ArchiveRead;

our @ISA = qw( Archive );

$ffi->attach( [ archive_read_new => 'new' ] => ['string'] => 'archive' );
$ffi->attach( [ archive_read_free => 'DESTROY' ] => ['archive'] => 'void' );
$ffi->attach( [ archive_read_support_filter_all => 'support_filter_all' ] => ['archive'] => 'int' );
$ffi->attach( [ archive_read_support_format_all => 'support_format_all' ] => ['archive'] => 'int' );
$ffi->attach( [ archive_read_open_filename => 'open_filename' ] => ['archive','string','size_t'] => 'int' );
$ffi->attach( [ archive_read_next_header2 => 'next_header2' ] => ['archive', 'archive_entry' ] => 'int' );
$ffi->attach( [ archive_read_data_skip => 'data_skip' ] => ['archive'] => 'int' );
# ... define additional read methods

package ArchiveWrite;

our @ISA = qw( Archive );

$ffi->attach( [ archive_write_new => 'new' ] => ['string'] => 'archive' );
$ffi->attach( [ archive_write_free => 'DESTROY' ] => ['archive'] => 'void' );
# ... define additional write methods

package ArchiveEntry;

$ffi->attach( [ archive_entry_new => 'new' ] => ['string'] => 'archive_entry' );
$ffi->attach( [ archive_entry_free => 'DESTROY' ] => ['archive_entry'] => 'void' );
$ffi->attach( [ archive_entry_pathname => 'pathname' ] => ['archive_entry'] => 'string' );
# ... define additional entry methods

package main;

use constant ARCHIVE_OK => 0;

# this is a Perl version of the C code here:
# https://github.com/libarchive/libarchive/wiki/Examples#List_contents_of_Archive_stored_in_File

my $archive_filename = shift @ARGV;
die "usage: $0 archive.tar" unless defined $archive_filename;

my $archive = ArchiveRead->new;
$archive->support_filter_all;
$archive->support_format_all;

my $r = $archive->open_filename($archive_filename, 1024);
die "error opening $archive_filename: ", $archive->error_string
  unless $r == ARCHIVE_OK;

my $entry = ArchiveEntry->new;

while($archive->next_header2($entry) == ARCHIVE_OK)
{
  print $entry->pathname, "\n";
  $archive->data_skip;
}

