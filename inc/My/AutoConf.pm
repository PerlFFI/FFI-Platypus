package My::AutoConf;

use strict;
use warnings;
use Config;
use File::Spec;
use FindBin;
use My::ShareConfig;
use My::ConfigH;
use lib 'lib';
use FFI::Probe;
use FFI::Probe::Runner;

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
uint8_t
int8_t
uint16_t
int16_t
uint32_t
int32_t
uint64_t
int64_t
size_t
ssize_t
float
double
long double
float complex
double complex
long double complex
bool
_Bool
pointer
EOF

my @extra_probe_types = split /\n/, <<EOF;
long long
signed long long
unsigned long long
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
ptrdiff_t
wchar_t
wint_t
EOF

push @probe_types, @extra_probe_types unless $ENV{FFI_PLATYPUS_NO_EXTRA_TYPES};

my $config_h = File::Spec->rel2abs( File::Spec->catfile( 'include', 'ffi_platypus_config.h' ) );

sub configure
{
  my($self) = @_;

  my $share_config = My::ShareConfig->new;
  my $probe = FFI::Probe->new(
    runner => FFI::Probe::Runner->new(
      exe => "blib/lib/auto/share/dist/FFI-Platypus/probe/bin/dlrun$Config{exe_ext}",
    ),
    log => "config.log",
    data_filename => "blib/lib/auto/share/dist/FFI-Platypus/probe/probe.pl",
  );

  return if -r $config_h && ref($share_config->get( 'type_map' )) eq 'HASH';

  my $ac = My::ConfigH->new;

  $ac->define_var( do {
    my $os = uc $^O;
    $os =~ s/-/_/;
    $os =~ s/[^A-Z0-9_]//g;
    "PERL_OS_$os";
  } => 1 );

  $ac->define_var( PERL_OS_WINDOWS => 1 ) if $^O =~ /^(MSWin32|cygwin|msys)$/;

  foreach my $header (qw( stdlib stdint sys/types sys/stat unistd alloca dlfcn limits stddef wchar signal inttypes windows sys/cygwin string psapi stdio stdbool complex ))
  {
    if($probe->check_header("$header.h"))
    {
      my $var = uc $header;
      $var =~ s{/}{_}g;
      $var = "HAVE_${var}_H";
      $ac->define_var( $var => 1 );
    }
  }

  if(!$share_config->get('config_debug_fake32') && $Config{ivsize} >= 8)
  {
    $ac->define_var( HAVE_IV_IS_64 => 1 );
  }
  else
  {
    $ac->define_var( HAVE_IV_IS_64 => 0 );
  }

  my %type_map;
  my %align;

  foreach my $type (@probe_types)
  {
    my $ok;

    if($type =~ /^(float|double|long double)/)
    {
      if(my $basic = $probe->check_type_float($type))
      {
        $type_map{$type} = $basic;
        $align{$type} = $probe->data->{type}->{$type}->{align};
      }
    }
    elsif($type eq 'pointer')
    {
      $probe->check_type_pointer;
      $align{pointer} = $probe->data->{type}->{pointer}->{align};
    }
    else
    {
      if(my $basic = $probe->check_type_int($type))
      {
        $type_map{$type} = $basic;
        $align{$basic} ||= $probe->data->{type}->{$type}->{align};
      }
    }
  }

  $ac->define_var( SIZEOF_VOIDP => $probe->data->{type}->{pointer}->{size} );
  if(my $size = $probe->data->{type}->{'float complex'}->{size})
  { $ac->define_var( SIZEOF_FLOAT_COMPLEX => $size ) }
  if(my $size = $probe->data->{type}->{'double complex'}->{size})
  { $ac->define_var( SIZEOF_DOUBLE_COMPLEX => $size ) }
  if(my $size = $probe->data->{type}->{'long double complex'}->{size})
  { $ac->define_var( SIZEOF_LONG_DOUBLE_COMPLEX => $size ) }

  # short aliases
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

  $ac->write_config_h;
  $share_config->set( type_map => \%type_map );
  $share_config->set( align    => \%align    );
}

sub clean
{
  unlink $config_h;
}

1;
