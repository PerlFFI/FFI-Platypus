use strict;
use warnings;
use File::chdir;
use File::Glob qw( bsd_glob );
use File::Temp qw( tempdir );

my $lib = tempdir( CLEANUP => 1 );

my @cmd = ( 'cpanm', '-n', '-l' => $lib, 'FFI::TinyCC', 'FFI::Platypus::Type::StringArray', );
print "+ @cmd\n";
system @cmd;
exit 2 if $?;

do {

  local $CWD = 'examples';
  
  foreach my $cfile (bsd_glob '*.c')
  {
    my $sofile = $cfile;
    $sofile =~ s{\.c$}{.so};
    
    my @cmd = ('cc', '-fPIC', '-shared', -o => $sofile, $cfile);
    print "+ @cmd\n";
    system @cmd;
    exit 2 if $?;
  }

  foreach my $plfile (bsd_glob '*.pl')
  {
    next if $plfile =~ /^win32_/;
    my @cmd = ( $^X, "-Mlocal::lib=$lib", $plfile );
    print "+ @cmd\n";
    system @cmd;
    exit 2 if $?;
  }

};

do {

  local $CWD = 'examples/java';

  do {
    my @cmd = ('make');
    print "+ @cmd\n";
    system @cmd;
    exit 2 if $?;
  };

  foreach my $plfile (bsd_glob '*.pl')
  {
    next if $plfile =~ /^win32_/;
    my @cmd = ( $^X, "-Mlocal::lib=$lib", $plfile );
    print "+ @cmd\n";
    system @cmd;
    exit 2 if $?;
  }

};
