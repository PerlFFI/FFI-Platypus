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
#ifdef HAVE_STDINT_H
#include <stdint.h>
#endif
#ifdef HAVE_COMPLEX_H
#include <complex.h>
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
bool
_Bool
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
  
  $ac->define_var( PERL_OS_WINDOWS => 1 ) if $^O =~ /^(MSWin32|cygwin|msys)$/;
  
  foreach my $header (qw( stdlib stdint sys/types sys/stat unistd alloca dlfcn limits stddef wchar signal inttypes windows sys/cygwin string psapi stdio stdbool complex ))
  {
    $ac->check_header("$header.h");
  }

  $ac->check_stdc_headers;

  if($ac->check_decl('RTLD_LAZY', { prologue => $prologue }))
  {
    $ac->define_var( HAVE_RTLD_LAZY => 1 );
  }
  
  unless($mb->config_data('config_no_alloca'))
  {
    if($ac->check_decl('alloca', { prologue => $prologue }))
    {
      $ac->define_var( HAVE_ALLOCA => 1 );
    }
  }
  
  if(!$mb->config_data('config_debug_fake32') && $Config{ivsize} >= 8)
  {
    $ac->define_var( HAVE_IV_IS_64 => 1 );
  }
  else
  {
    $ac->define_var( HAVE_IV_IS_64 => 0 );
  }
  
  foreach my $lib (map { s/^-l//; $_ } split /\s+/, $Config{perllibs})
  {
    if($ac->check_lib($lib, 'dlopen'))
    {
      $ac->define_var( 'HAVE_dlopen' => 1 );
      last;
    }
  }

  my %type_map;

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
    }
  }

  $type_map{uchar}  = $type_map{'unsigned char'};
  $type_map{ushort} = $type_map{'unsigned short'};
  $type_map{uint}   = $type_map{'unsigned int'};
  $type_map{ulong}  = $type_map{'unsigned long'};

  # on Linux and OS X at least the test for bool fails
  # but _Bool works (even though code using bool seems
  # to work for both).  May be because bool is a macro
  # for _Bool or something.
  $type_map{bool} ||= delete $type_map{_Bool};
  delete $type_map{_Bool};

  $ac->check_default_headers;

  my %align = (
    pointer          => _alignment($ac, 'void*'),
    float            => _alignment($ac, 'float'),
    double           => _alignment($ac, 'double'),
    'long double'    => _alignment($ac, 'long double'),
    'float complex'  => _alignment($ac, 'float complex'),
    'double complex' => _alignment($ac, 'double complex'),
  );

  foreach my $bits (qw( 8 16 32 64 ))
  {
    $align{'sint'.$bits} = $align{'uint'.$bits} = _alignment($ac, "int${bits}_t");
  }
  
  if($ac->check_sizeof_type('long double',    { prologue => $prologue }))
  {
    $type_map{'long double'} = 'longdouble';
  }
  
  if($ac->check_sizeof_type('float complex',  { prologue => $prologue }))
  {
    $type_map{'float complex'} = 'complex_float';
  }

  if($ac->check_sizeof_type('double complex', { prologue => $prologue }))
  {
    $type_map{'double complex'} = 'complex_double';
  }

  if(my $size = $ac->check_sizeof_type('complex', { prologue => $prologue }))
  {
    if($size == 8)
    {
      $type_map{'complex'} = 'complex_float';
    }
    elsif($size == 16)
    {
      $type_map{'complex'} = 'complex_double';
    }
  }
  
  $mb->add_to_cleanup( $config_h );
  $ac->write_config_h( $config_h );
  $mb->config_data( type_map => \%type_map );
  $mb->config_data( align    => \%align    );
}

sub _alignment
{
  my($ac, $type) = @_;
  my $align = $ac->check_alignof_type($type);
  return $align if $align;
  
  # This no longer seems necessary now that we do a
  # check_default_headers above.  See:
  # # https://github.com/ambs/Config-AutoConf/issues/7
  my $btype = $type eq 'void*' ? 'vpointer' : "b$type";
  $btype =~ s/\s+/_/g;
  my $prologue2 = $prologue . <<EOF;
#ifdef HAVE_COMPLEX_H
#include <complex.h>
#endif
struct align {
  char a;
    $type $btype;
  };
EOF
  return $ac->compute_int("__builtin_offsetof(struct align, $btype)", { prologue => $prologue2 });
}

sub clean
{
  unlink $config_h;
}

1;
