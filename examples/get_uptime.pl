#!perl
#Description: Get linux system uptime using GNOME libgtop library and FFI::Platypus
#Refer: https://developer.gnome.org/libgtop/stable/libgtop-Uptime.html
#Author: Bakkiaraj M
use strict;
use warnings;
use FFI::Platypus;
use FFI::CheckLib;
use Convert::Binary::C;
use Time::Seconds;

#Find the lib
my $lib_path = find_lib(lib=>'gtop-2.0',libpath=>'/usr/lib64');

print "\n Found libgtop in :", $lib_path;

#Create FFI::Platypus object
my $ffi = FFI::Platypus->new();
$ffi->lib($lib_path);

#Create Convert::Binary::C object to import the structures 
my $c_struct = Convert::Binary::C->new();
$c_struct->configure( 'Alignment' => 0 );

#import glibtop_uptime struct using Convert::Binary::C
#Note: guint64 is unsigned long as per 
#http://www.freedesktop.org/software/gstreamer-sdk/data/docs/latest/glib/glib-Basic-Types.html#guint64

$c_struct->parse(<<ENDC);
struct glibtop_uptime {
    unsigned long flags;
    double uptime;      /* GLIBTOP_UPTIME_UPTIME */
    double idletime; /* GLIBTOP_UPTIME_IDLETIME */
    unsigned long boot_time;
};
ENDC

my $packed_glibtop_uptime_struct = $c_struct->pack('glibtop_uptime',{});

#Get size of the glibtop_uptime
my $glibtop_uptime_size = $c_struct->sizeof('glibtop_uptime');

#typecast the glibtop_uptime as a FFI::Platypus record
$ffi->type("record($glibtop_uptime_size)"=>'glibtop_uptime');
#import glibtop_get_uptime function from libgtop to perl
$ffi->attach('glibtop_get_uptime',['glibtop_uptime'],'void');

#Call glibtop_get_uptime
glibtop_get_uptime ($packed_glibtop_uptime_struct);

#unpack the structure
my $glibtop_uptime_struct = $c_struct->unpack('glibtop_uptime',$packed_glibtop_uptime_struct);
#print "\n", Dumper($glibtopUptimeStruct);
print "\n System is upfor: ", $glibtop_uptime_struct->{'uptime'}," Sec";

my $time = Time::Seconds->new($glibtop_uptime_struct->{'uptime'});
print "\n System is upfor: ",$time->pretty;

#using uptime command
print "\n\n System is upfor:";
system('uptime -p');
