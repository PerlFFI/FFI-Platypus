#!perl
# Author : Bakkiaraj M
# Script: Get System time from windows OS using GetLocalTime API.
use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus;
use Convert::Binary::C;

#Get the system time using Kernel32.dll

#find the Kernel32.dll 
my $libPath = find_lib(lib=>'Kernel32');
#Create FFI Object
my $ffiObj = FFI::Platypus->new();
$ffiObj->lib($libPath);

#Import the GetLocalTime function
$ffiObj->attach('GetLocalTime',['record(16)'],'void');

#Define SYSTEMTIME Struct as per https://msdn.microsoft.com/en-us/library/windows/desktop/ms724950(v=vs.85).aspx
#As per, C:\MinGW\include\windef.h, WORD id unsigned short
my $c = Convert::Binary::C->new->parse(<<ENDC);
  
struct SYSTEMTIME {
  unsigned short wYear;
  unsigned short wMonth;
  unsigned short wDayOfWeek;
  unsigned short wDay;
  unsigned short wHour;
  unsigned short wMinute;
  unsigned short wSecond;
  unsigned short wMilliseconds;
  };
  
ENDC


my $dateStruct = {
  wYear=>0,
  wMonth=>0,
  wDayOfWeek=>0,
  wDay=>0,
  wHour=>0,
  wMinute=>0,
  wSecond=>0,
  wMilliseconds=>0,
};

my $packed = $c->pack('SYSTEMTIME', $dateStruct);

#Call the function by passing the structure reference
GetLocalTime($packed);

if (defined ($packed))
{
  #Unpack the structure 
  my $sysDate = $c->unpack('SYSTEMTIME', $packed);
  print "\n WINDOWS SYSTEM TIME: ",$$sysDate{'wHour'},':',$$sysDate{'wMinute'},':',$$sysDate{'wSecond'},'.',$$sysDate{'wMilliseconds'},' ',$$sysDate{'wDay'},'/',$$sysDate{'wMonth'},'/',$$sysDate{'wYear'}, "\n";
}
else
{
  print "\n Something is wrong\n";
}

exit 0;
