#!perl
#Description: Create GNOME Desktop notifications using GNOME libgio library and FFI::Platypus
#Refer: https://developer.gnome.org/gio/2.42/gio-GNotification.html
#Author: Bakkiaraj Murugesan
use strict;
use warnings;
use FFI::Platypus;
use FFI::Platypus::Declare;
use FFI::CheckLib;
use Data::Dumper;

$|++;
my $ffiObj = "";
my $libPath = "";

print "\n Perl FFI::Platypus Gnome Notification Example";
#Find the lib
$libPath = find_lib(lib=>'gio-2.0',libpath=>'/usr/lib64');
my $gobjectLibPath = find_lib(lib=>'gobject-2.0',libpath=>'/usr/lib64');
my $glibLibPath = find_lib(lib=>'glib-2.0',libpath=>'/usr/lib64');

#Find the library Paths
print "\n Found libgio-2.0 in :", $libPath;
print "\n Found libgobject-2.0 in :", $gobjectLibPath;
print "\n Found libglib-2.0 in :", $glibLibPath;

#Create FFI::Platypus object
$ffiObj = FFI::Platypus->new();
$ffiObj->lang('C'); #FFI supports more than C language
$ffiObj->lib($libPath);

my $ffiObj1 = FFI::Platypus->new();
$ffiObj1->lang('C'); #FFI supports more than C language
$ffiObj1->lib($gobjectLibPath);

my $ffiObj2 = FFI::Platypus->new();
$ffiObj2->lang('C'); #FFI supports more than C language
$ffiObj2->lib($glibLibPath);

#Create gapplication
#g_application_new (const gchar *application_id,GApplicationFlags flags);
$ffiObj->attach('g_application_new',['string','int'],'opaque');

#Check application ID is valid 
$ffiObj->attach('g_application_id_is_valid',['string'],'int');
#Set GApplication Name
my $appName = 'perl.ffi.platypus.gnome.notify.example';
print "\n App Name $appName is valid? ",g_application_id_is_valid($appName); 
#G_APPLICATION_FLAGS_NONE is 0
my $GApplicationPrt = g_application_new ($appName,0);

#Register the application
#gboolean g_application_register (GApplication *application, GCancellable *cancellable, GError **error);
$ffiObj->attach('g_application_register',['opaque','opaque','opaque'],'int');
#GCancellable *g_cancellable_new (void);
#$ffiObj->attach('g_cancellable_new',['void'],'void');
#my $GCancellablePtr = g_cancellable_new();
print "\n Application Registration ID:", g_application_register($GApplicationPrt,undef,undef);

print "\n Send Welcome notification";
#Create GNotification                        
#GNotification *g_notification_new (const gchar *title);
$ffiObj->attach('g_notification_new',['string'],'opaque');
my $GNotificationPtr = g_notification_new('Welcome');

#void g_notification_set_body (GNotification *notification, const gchar *body);
$ffiObj->attach('g_notification_set_body',['opaque','string'],'void');

g_notification_set_body ($GNotificationPtr, "Welcome to GNotifications using perl + FFI::Platypus...");

#void g_application_send_notification (GApplication *application, const gchar *id, GNotification *notification);
$ffiObj->attach('g_application_send_notification',['opaque','string','opaque'],'void');
g_application_send_notification($GApplicationPrt,'perl.ffi.platypus.gnome.notify.welcome',$GNotificationPtr);

print "\n Send Urgent notification";
#void g_notification_set_urgent (GNotification *notification, gboolean urgent);
$ffiObj->attach('g_notification_set_priority',['opaque','int'],'void');
$GNotificationPtr = g_notification_new('Urgent');
g_notification_set_body ($GNotificationPtr, "This is Urgent Notification. Have a look at me!");
g_notification_set_priority($GNotificationPtr,2);
g_application_send_notification($GApplicationPrt,'perl.ffi.platypus.gnome.notify.urgent',$GNotificationPtr);

print "\n Notification with Buttons";
$GNotificationPtr = g_notification_new('Wanna Coffee?');
g_notification_set_body ($GNotificationPtr, "Would you like to drink Coffee?");

                 
#void g_notification_add_button (GNotification *notification,const gchar *label,const gchar *detailed_action);
$ffiObj->attach('g_notification_add_button',['opaque','string','string'],'void');
g_notification_add_button ($GNotificationPtr, "Ok. Sure", "app.ok");


g_application_send_notification($GApplicationPrt,'perl.ffi.platypus.gnome.notify.coffee',$GNotificationPtr);
                        
print "\n Clean Up everything";
#Do clean up
#void g_object_unref (gpointer object);
$ffiObj1->attach('g_object_unref',['opaque'],'void');
g_object_unref ($GNotificationPtr);
g_object_unref ($GApplicationPrt);

print "\n Ta Ta from PID:", $$;
print "\n Note: GNotification is persitant, Even after this application quit, System reboot, Notification will be there until user acknowledge it.";
#All is Well Bye
exit 0;
