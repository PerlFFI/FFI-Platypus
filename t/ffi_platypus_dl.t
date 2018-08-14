use strict;
use warnings;
use Test::More;
use FFI::Platypus::DL;
use FFI::CheckLib qw( find_lib );

my $libtest = find_lib lib => 'test', symbol => 'f0', libpath => 't/ffi';

subtest 'flags' => sub {

  ok(FFI::Platypus::DL->can('RTLD_PLATYPUS_DEFAULT'), "RTLD_PLATYPUS_DEFAULT is defined");
  
  note "$_=@{[ FFI::Platypus::DL->can($_)->() ]}" for sort grep /^RTLD_/, keys %main::;

};

subtest 'dlopen' => sub {

  subtest 'bad library' => sub {
    is dlopen("t/ffi/libbogus.so", RTLD_PLATYPUS_DEFAULT), undef, 'Returns undef on fail';
    note "dlerror = @{[ dlerror ]}";
  };

  subtest 'good library' => sub {
    my $h = dlopen $libtest, RTLD_PLATYPUS_DEFAULT;
    ok($h, "Returns handle on good");
    note "h = $h";
    dlclose $h;
  };

};

subtest 'dlsym' => sub {

  my $h = dlopen $libtest, RTLD_PLATYPUS_DEFAULT;

  subtest 'good symbol' => sub {
    my $address = dlsym $h, 'f0';
    ok $address, 'returns an address';
    note "address = $address";
  };
  
  subtest 'bad symbol' => sub {
    my $address = dlsym $h, 'bogus';
    is $address, undef, 'bad symbol returns undef';
    note "dlerror = @{[ dlerror ]}";
  };
  
  dlclose $h;

};

done_testing;

