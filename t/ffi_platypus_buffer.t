use strict;
use warnings;
use utf8;
use B;

# see https://github.com/Perl5-FFI/FFI-Platypus/issues/85
use if $^O ne 'MSWin32' || $] >= 5.018, 'open', ':std', ':encoding(utf8)';
use Test::More;
use Encode qw( decode );
use FFI::Platypus::Buffer;
use FFI::Platypus::Buffer qw( scalar_to_pointer grow set_used_length );

subtest simple => sub {
  my $orig = 'me grimlock king';
  my($ptr, $size) = scalar_to_buffer($orig);
  ok $ptr, "ptr = $ptr";
  my $ptr2 = scalar_to_pointer($orig);
  is $ptr2, $ptr, "scalar to pointer matches";
  is $size, 16, 'size = 16';
  my $scalar = buffer_to_scalar($ptr, $size);
  is $scalar, 'me grimlock king', "scalar = $scalar";
};

subtest unicode => sub {
  my $orig = 'привет';
  my($ptr, $size) = scalar_to_buffer($orig);
  ok $ptr, "ptr = $ptr";
  ok $size, "size = $size";
  my $scalar = decode('UTF-8', buffer_to_scalar($ptr, $size));
  is $scalar, 'привет', "scalar = $scalar";
};

subtest grow => sub {
    my $orig = 'me grimlock king';
    my($ptr, $size) = scalar_to_buffer($orig);
    my $sv = B::svref_2object( \$orig );
    is $sv->CUR, $size, "B::PV returns consistent string length";

    my $required = 100;
    ok $sv->LEN < $required, "initial buffer size is smaler than required";

  subtest 'default options' => sub {
    my $str = $orig;
    grow( $str, $required );
    my $sv = B::svref_2object( \$str );
    ok $sv->LEN >= $required, "buffer grew as expected";
    is $sv->CUR, 0,  "buffer contents cleared";
  };

  subtest clear => sub {

    subtest 'on' => sub {
      my $str = $orig;
      grow( $str, $required, { clear => 1 }  );
      my $sv = B::svref_2object( \$str );
      ok $sv->LEN >= $required, "buffer grew as expected";
      is $sv->CUR, 0,  "buffer contents cleared";
    };

    subtest 'off' => sub {
      my $str = $orig;
      grow( $str, $required, { clear => 0 }  );
      my $sv = B::svref_2object( \$str );
      ok $sv->LEN >= $required, "buffer grew as expected";
      is $str, $orig,  "buffer contents not cleared";
    };

  };

  subtest set_length => sub {

    subtest 'on' => sub {
      my $str = $orig;
      grow( $str, $required, { set_length => 1 }  );
      my $sv = B::svref_2object( \$str );
      ok $sv->LEN >= $required, "buffer grew as expected";
      is $sv->CUR, $required,  "buffer length set";
    };

    subtest 'off' => sub {
      my $str = $orig;
      grow( $str, $required, { set_length => 0, clear => 1 }  );
      my $sv = B::svref_2object( \$str );
      ok $sv->LEN >= $required, "buffer grew as expected";
      is $sv->CUR, 0,  "buffer length not cleared";
    };

  };

  subtest "bad option" => sub {
      my $str;
      eval{ grow( $str, 100, { 'bad option' => 1 } ) };
      my $err = $@;
      like ( $err, qr/bad option/, "croaked" );
  };

  subtest "fail on reference" => sub {
    my $ref = \$orig;
    eval { grow( $ref, 0 ); };
    my $err = $@;
    like ( $err, qr/must be a scalar/, "croaked" );
  };

  subtest '$str = undef' => sub {
    my $str;
    grow( $str, $required );
    my $sv = B::svref_2object( \$str );
    ok $sv->LEN >= $required, "buffer grew as expected";
  };

  subtest 'undef' => sub {
    eval { grow( undef, $required ) };
    my $err = $@;
    like ( $err, qr/read-only/, "croaked" );
  };
};

subtest set_used_length => sub {
    my $orig = 'me grimlock king';

   subtest 'length < max' => sub {
      my $str = $orig;
      my $len = set_used_length( $str, 3 );
      is( $len, 3, "requested length" );
      is( $str, "me ", "requested string" );
   };

   subtest 'length == max' => sub {
      my $str = $orig;
      my $sv = B::svref_2object( \$str );
      my $len = set_used_length( $str, $sv->LEN );
      is( $len, $sv->LEN, "requested length" );
   };

   subtest 'length > max' => sub {
      my $str = $orig;
      my $sv = B::svref_2object( \$str );
      my $len = set_used_length( $str, $sv->LEN + 10);
      is( $len, $sv->LEN, "maxed out length" );
   };

  subtest "fail on reference" => sub {
    my $ref = \$orig;
    eval { set_used_length( $ref, 0 ); };
    my $err = $@;
    like ( $err, qr/must be a scalar/, "croaked" );
  };

TODO : {

  local $TODO = "is set_used_length undef behavior correct?";

  subtest '$str = undef' => sub {
    my $str;
    my $len = set_used_length( $str, 100);
    my $sv = B::svref_2object( \$str );
    is ( $len, 0, "no added length" );
    is( $len, $sv->LEN, "maxed out length" );
  };

}

  subtest 'undef' => sub {
    eval { set_used_length( undef, 0 ) };
    my $err = $@;
    like ( $err, qr/read-only/, "croaked" );
  };
};

done_testing;
