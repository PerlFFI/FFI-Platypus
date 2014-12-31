requires "JSON::PP" => "0";
requires "perl" => "5.008001";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "FFI::CheckLib" => "0";
  requires "Test::More" => "0.94";
  requires "perl" => "5.008001";
};

on 'configure' => sub {
  requires "Alien::FFI" => "0.02";
  requires "Config::AutoConf" => "0";
  requires "ExtUtils::CBuilder" => "0";
  requires "Module::Build" => "0.28";
  requires "perl" => "5.006";
};

on 'develop' => sub {
  requires "Devel::PPPort" => "3.23";
};
