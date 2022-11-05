use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use constant CURLOPT_URL => 10002;

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => find_lib_or_die(lib => 'curl'),
);

my $curl_handle = $ffi->function( 'curl_easy_init' => [] => 'opaque' )
                      ->call;

$ffi->function( 'curl_easy_setopt' => ['opaque', 'enum' ] => ['string'] )
    ->call($curl_handle, CURLOPT_URL, "https://pl.atypus.org" );

$ffi->function( 'curl_easy_perform' => ['opaque' ] => 'enum' )
    ->call($curl_handle);

$ffi->function( 'curl_easy_cleanup' => ['opaque' ] )
    ->call($curl_handle);
