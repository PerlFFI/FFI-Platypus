use Test2::V0 -no_srand => 1;
use FFI::Platypus::Lang::Win32;

{
  require FFI::Platypus::Type::WideString;
  my($encoding,$width) = eval { FFI::Platypus::Type::WideString->_compute_wide_string_encoding() };
  if(my $error = $@)
  {
    $error =~ s/ at .*$//;
    plan skip_all => "Unable to detect wide string details: $error\n";
  }

  note "encoding = $encoding";
  note "width    = $width";
}

subtest 'native type map diagnostic' => sub {

  my $map = FFI::Platypus::Lang::Win32->native_type_map;

  foreach my $alias (sort keys %$map)
  {
    my $type = $map->{$alias};
    note sprintf("%-30s %s", $alias, $type);
  }

  pass 'good';
};

my $ffi = FFI::Platypus->new( api => 1, lib => [undef] );

subtest 'load' => sub {
  local $@ = "";
  eval { $ffi->lang('Win32') };
  is "$@", "";
};

my @strings = (
  [ "trivial" => "" ],
  [ "simple"  => "abcde" ],
  [ "fancy"   => "abcd\x{E9}" ],
  [ "complex" => "I \x{2764} Platypus" ],
);

subtest 'LPCWSTR' => sub {
  plan skip_all => 'Test only works on Windows' unless $^O eq 'MSWin32';

  my $lstrlenW = $ffi->function( lstrlenW => [ 'LPCWSTR' ] => 'int' );

  foreach my $test (@strings)
  {
    my($name, $string) = @$test;
   is($lstrlenW->call($string), length($string), $name);
  }
};

subtest 'LPWSTR' => sub {
  plan skip_all => 'Test only works on Windows' unless $^O eq 'MSWin32';

  my $GetCurrentDirectoryW = $ffi->function( GetCurrentDirectoryW => ['DWORD','LPWSTR'] => 'DWORD' );

  my $size = $GetCurrentDirectoryW->call(0, undef);
  cmp_ok $size, '>', 0;

  my $buf = "\0" x ($size*2);
  $GetCurrentDirectoryW->call($size, \$buf);

  note "buf = $buf";

  ok( -d $buf, "returned directory exists");
};

done_testing;
