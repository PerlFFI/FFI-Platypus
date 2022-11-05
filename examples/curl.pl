use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use constant CURLOPT_URL => 10002;

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => find_lib_or_die(lib => 'curl'),
);

# https://curl.se/libcurl/c/curl_easy_init.html
my $curl_handle = $ffi->function( 'curl_easy_init' => [] => 'opaque' )
                      ->call;

# https://curl.se/libcurl/c/curl_easy_setopt.html
$ffi->function( 'curl_easy_setopt' => ['opaque', 'enum' ] => ['string'] )
    ->call($curl_handle, CURLOPT_URL, "https://pl.atypus.org" );

# https://curl.se/libcurl/c/curl_easy_perform.html
$ffi->function( 'curl_easy_perform' => ['opaque' ] => 'enum' )
    ->call($curl_handle);

# https://curl.se/libcurl/c/curl_easy_cleanup.html
$ffi->function( 'curl_easy_cleanup' => ['opaque' ] )
    ->call($curl_handle);
