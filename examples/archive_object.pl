use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );

# This example uses FreeBSD's libarchive to list the contents of any
# archive format that it suppors.  We've also filled out a part of
# the ArchiveWrite class that could be used for writing archive formats
# supported by libarchive

my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib(find_lib_or_die lib => 'archive');
$ffi->type('object(Archive)'      => 'archive_t');
$ffi->type('object(ArchiveRead)'  => 'archive_read_t');
$ffi->type('object(ArchiveWrite)' => 'archive_write_t');
$ffi->type('object(ArchiveEntry)' => 'archive_entry_t');

package Archive {
  # base class is "abstract" having no constructor or destructor

  $ffi->mangler(sub {
    my($name) = @_;
    "archive_$name";
  });
  $ffi->attach( error_string => ['archive_t'] => 'string' );
}

package ArchiveRead {
  our @ISA = qw( Archive );

  $ffi->mangler(sub {
    my($name) = @_;
    "archive_read_$name";
  });

  $ffi->attach( new                   => ['string']                        => 'archive_read_t' );
  $ffi->attach( [ free => 'DESTROY' ] => ['archive_t']                                         );
  $ffi->attach( support_filter_all    => ['archive_t']                     => 'int'            );
  $ffi->attach( support_format_all    => ['archive_t']                     => 'int'            );
  $ffi->attach( open_filename         => ['archive_t','string','size_t']   => 'int'            );
  $ffi->attach( next_header2          => ['archive_t', 'archive_entry_t' ] => 'int'            );
  $ffi->attach( data_skip             => ['archive_t']                     => 'int'            );
  # ... define additional read methods
}

package ArchiveWrite {

  our @ISA = qw( Archive );

  $ffi->mangler(sub {
    my($name) = @_;
    "archive_write_$name";
  });

  $ffi->attach( new                   => ['string'] => 'archive_write_t' );
  $ffi->attach( [ free => 'DESTROY' ] => ['archive_write_t'] );
  # ... define additional write methods
}

package ArchiveEntry {

  $ffi->mangler(sub {
    my($name) = @_;
    "archive_entry_$name";
  });

  $ffi->attach( new => ['string']     => 'archive_entry_t' );
  $ffi->attach( [ free => 'DESTROY' ] => ['archive_entry_t'] );
  $ffi->attach( pathname              => ['archive_entry_t'] => 'string' );
  # ... define additional entry methods
}

use constant ARCHIVE_OK => 0;

# this is a Perl version of the C code here:
# https://github.com/libarchive/libarchive/wiki/Examples#List_contents_of_Archive_stored_in_File

my $archive_filename = shift @ARGV;
unless(defined $archive_filename)
{
  print "usage: $0 archive.tar\n";
  exit;
}

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
