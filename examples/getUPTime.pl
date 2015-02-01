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
use Data::Dumper;

#Globals
my $ffiObj = "";
my $libPath = "";
my $cStructObj = "";
my $glibtopUptimeSize = 0;
my $glibtopUptimeStruct = undef;
my $packedglibtopUptimeStruct = undef;
my $timeObj = "";

#Find the lib
$libPath = find_lib(lib=>'gtop-2.0',libpath=>'/usr/lib64');


print "\n Found libgtop in :", $libPath;

#Create FFI::Platypus object
$ffiObj = FFI::Platypus->new();
$ffiObj->lib($libPath);

#Create Convert::Binary::C object to import the structures 
$cStructObj = Convert::Binary::C->new();
$cStructObj->configure( 'Alignment' => 0 );

#import glibtop_uptime struct using Convert::Binary::C
#Note: guint64 is unsigned long as per 
#http://www.freedesktop.org/software/gstreamer-sdk/data/docs/latest/glib/glib-Basic-Types.html#guint64

$cStructObj->parse(<<ENDC);
struct glibtop_uptime {
    unsigned long flags;
    double uptime;      /* GLIBTOP_UPTIME_UPTIME */
    double idletime; /* GLIBTOP_UPTIME_IDLETIME */
    unsigned long boot_time;
};
ENDC

$glibtopUptimeStruct = {};
$packedglibtopUptimeStruct = $cStructObj->pack('glibtop_uptime',$glibtopUptimeStruct);

#Get size of the glibtop_uptime
$glibtopUptimeSize = $cStructObj->sizeof('glibtop_uptime');

#typecast the glibtop_uptime as a FFI::Platypus record
$ffiObj->type("record($glibtopUptimeSize)"=>'glibtop_uptime');
#import glibtop_get_uptime function from libgtop to perl
$ffiObj->attach('glibtop_get_uptime',['glibtop_uptime'],'void');

#Call glibtop_get_uptime
glibtop_get_uptime ($packedglibtopUptimeStruct);

#unpack the structure
$glibtopUptimeStruct = $cStructObj->unpack('glibtop_uptime',$packedglibtopUptimeStruct);
#print "\n", Dumper($glibtopUptimeStruct);
print "\n System is upfor: ", $glibtopUptimeStruct->{'uptime'}," Sec";

$timeObj = Time::Seconds->new($glibtopUptimeStruct->{'uptime'});
print "\n System is upfor: ",$timeObj->pretty;

#using uptime command
print "\n\n System is upfor:";
system('uptime -p');

exit (0);

 