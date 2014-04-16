use strict;
use warnings;
use Test::More;
BEGIN { 
  plan skip_all => 'test requires Test::Spelling' 
    unless eval q{ use Test::Spelling; 1 };
  plan skip_all => 'test requires YAML'
    unless eval q{ use YAML; 1; };
};
use Test::Spelling;
use YAML qw( LoadFile );
use FindBin;
use File::Spec;

my $config_filename = File::Spec->catfile(
  $FindBin::Bin, 'release.yml'
);

my $config;
$config = LoadFile($config_filename)
  if -r $config_filename;

plan skip_all => 'disabled' if $config->{pod_spelling_system}->{skip};

chdir(File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir));

add_stopwords(@{ $config->{pod_spelling_system}->{stopwords} });
add_stopwords(<DATA>);
all_pod_files_spelling_ok;

__DATA__
Plicease
stdout
stderr
stdin
subref
loopback
username
os
Ollis
Mojolicious
plicease
CPAN
reinstall
TODO
filename
filenames
login
callback
callbacks
standalone
VMS
hostname
hostnames
TCP
UDP
IP
API
MSWin32
OpenBSD
FreeBSD
NetBSD
unencrypted
WebSocket
WebSockets
timestamp
timestamps
poney
BackPAN
portably
RedHat
AIX
BSD
XS
FFI
perlish
optimizations
subdirectory
RESTful
SQLite
JavaScript
dir
plugins
munge
jQuery
namespace
PDF
PDFs
usernames
DBI
pluggable
APIs
SSL
JSON
YAML
uncommented
Solaris
OpenVMS
URI
URL
CGI
