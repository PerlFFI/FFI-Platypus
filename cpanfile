requires "ExtUtils::CBuilder" => "0";
requires "FFI::CheckLib" => "0";
requires "File::ShareDir" => "0";
requires "JSON::PP" => "0";
requires "Module::Build" => "0.3601";
requires "constant" => "1.32";
requires "perl" => "5.008001";

on 'build' => sub {
  requires "Module::Build" => "0.3601";
};

on 'test' => sub {
  requires "Alien::FFI" => "0.012";
  requires "Test::More" => "0.94";
  requires "perl" => "5.008001";
};

on 'configure' => sub {
  requires "Alien::FFI" => "0.12";
  requires "Config::AutoConf" => "0.309";
  requires "ExtUtils::CBuilder" => "0";
  requires "FFI::CheckLib" => "0.05";
  requires "Module::Build" => "0.3601";
  requires "perl" => "5.008001";
};

on 'develop' => sub {
  requires "Devel::PPPort" => "3.28";
};
