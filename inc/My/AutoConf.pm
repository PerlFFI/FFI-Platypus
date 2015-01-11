package My::AutoConf;

use strict;
use warnings;
use Config::AutoConf;
use Config;
use File::Spec;
use FindBin;

my $root = $FindBin::Bin;

my $prologue = <<EOF;
#ifdef HAVE_DLFCN_H
#include <dlfcn.h>
#endif
#ifdef HAVE_ALLOCA_H
#include <alloca.h>
#endif
#define signed(type)  (((type)-1) < 0) ? 1 : 0
EOF

my @probe_types = split /\n/, <<EOF;
char
signed char
unsigned char
short
signed short
unsigned short
int
signed int
unsigned int
long
signed long
unsigned long
long long
signed long long
unsigned long long
size_t
dev_t
ino_t
mode_t
nlink_t
uid_t
gid_t
off_t
blksize_t
blkcnt_t
time_t
uint8_t
int8_t
uint16_t
int16_t
uint32_t
int32_t
uint64_t
int64_t
int_least8_t
int_least16_t
int_least32_t
int_least64_t
uint_least8_t
uint_least16_t
uint_least32_t
uint_least64_t
ptrdiff_t
wchar_t
wint_t
float
double
long double
EOF

my $config_h = File::Spec->rel2abs( File::Spec->catfile( 'include', 'ffi_platypus_config.h' ) );

sub configure
{
  my($self, $mb) = @_;
  
  return if -r $config_h && ref($mb->config_data( 'type_map' )) eq 'HASH';

  my $ac = Config::AutoConf->new;
  
  $ac->check_prog_cc;

  $ac->define_var( do { 
    my $os = uc $^O;
    $os =~ s/-/_/;
    $os =~ s/[^A-Z0-9_]//g;
    "PERL_OS_$os";
  } => 1 );
  
  $ac->define_var( PERL_OS_WINDOWS => 1 ) if $^O =~ /^(MSWin32|cygwin)$/;
  
  foreach my $header (qw( stdlib stdint sys/types sys/stat unistd alloca dlfcn limits stddef wchar signal inttypes windows sys/cygwin string psapi stdio ))
  {
    $ac->check_header("$header.h");
  }
  
  if($ac->check_decl('RTLD_LAZY', { prologue => $prologue }))
  {
    $ac->define_var( HAVE_RTLD_LAZY => 1 );
  }
  
  if($ac->check_decl('alloca', { prologue => $prologue }))
  {
    $ac->define_var( HAVE_ALLOCA => 1 );
  }
  
  if($Config{ivsize} >= 8)
  {
    $ac->define_var( HAVE_IV_IS_64 => 1 );
  }
  
  foreach my $lib (map { s/^-l//; $_ } split /\s+/, $Config{perllibs})
  {
    if($ac->check_lib($lib, 'dlopen'))
    {
      $ac->define_var( 'HAVE_dlopen' => 1 );
      last;
    }
  }

  my %type_map = map { $_ => $_ } qw( void sint8 uint8 sint16 uint16 sint32 uint32 sint64 uint64 float double string opaque );
  $type_map{pointer} = 'opaque';

  foreach my $type (@probe_types)
  {
    my $size = $ac->check_sizeof_type($type);
    if($size)
    {
      if($type !~ /^(float|double|long double)$/)
      {
        my $signed;
        if($type =~ /^signed / || $type =~ /^(int[0-9]+_t|int_least[0-9]+_t)$/)
        {
          $signed = 1;
        }
        elsif($type =~ /^unsigned / || $type =~ /^(uint[0-9]+_t|uint_least[0-9]+_t)$/)
        {
          $signed = 0;
        }
        $signed = $ac->compute_int("signed($type)", { prologue => $prologue })
          unless defined $signed;
        $type_map{$type} = sprintf "%sint%d", ($signed ? 's' : 'u'), $size*8;
      }
      else
      {
        if($type eq 'long double' && $size)
        {
          $type_map{'long double'} = $type_map{'longdouble'} = 'longdouble';
        }
      }
    }
  }
  
  $ac->write_config_h( $config_h );
  $mb->config_data( type_map => \%type_map);
}

sub clean
{
  unlink $config_h;
}

1;
