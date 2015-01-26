use strict;
use warnings;
use FFI::Platypus;
use FFI::CheckLib qw( find_lib_or_die );
use FFI::Platypus::Buffer qw( scalar_to_buffer buffer_to_scalar );
use FFI::Platypus::Memory qw( malloc free );

my $ffi = FFI::Platypus->new;
$ffi->lib(find_lib_or_die lib => 'bz2');

$ffi->attach(
  BZ2_bzBuffToBuffCompress => [
    'opaque',				# dest
    'unsigned int *',			# dest length
    'opaque',				# source
    'unsigned int',			# source length
    'int',				# blockSize100k
    'int',				# verbosity
    'int',				# workFactor
  ] => 'int',
);

$ffi->attach(
  BZ2_bzBuffToBuffDecompress => [
    'opaque',				# dest
    'unsigned int *',			# dest length
    'opaque',				# source
    'unsigned int',			# source length
    'int',				# small
    'int',				# verbosity
  ] => 'int',
);

sub compress ($)
{
  my($source,$source_length) = scalar_to_buffer($_[0]);
  my $dest_length = int(length($source)*1.01) + 1 + 600;
  my $dest = malloc $dest_length;
  my $r = BZ2_bzBuffToBuffCompress($dest, \$dest_length, $source, $source_length, 9, 0, 30);
  die "bzip2 error $r" unless $r == 0;
  my $compressed = buffer_to_scalar($dest, $dest_length);
  free $dest;
  $compressed;
};

sub decompress ($$)
{
  my($source, $source_length) = scalar_to_buffer($_[0]);
  my $dest_length = $_[1];
  my $dest = malloc $dest_length;
  my $r = BZ2_bzBuffToBuffDecompress($dest, \$dest_length, $source, $source_length, 0, 0);
  die "bzip2 error $r" unless $r == 0;
  my $decompressed = buffer_to_scalar($dest, $dest_length);
}

my $original = "hello compression world\n";
my $compressed = compress $original;
print decompress $compressed, length $original;

