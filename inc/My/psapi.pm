package My::psapi;

sub cflags {''}

sub libs
{
  if($^O eq 'MSWin32')
  {
	if($Config{ccname} eq 'cl')
	{
	  return "psapi.lib ";
	}
	else
	{
	  return "-lpsapi";
	}
  }
  elsif($^O eq 'cygwin' || $^O eq 'msys')
  {
    return "-L/usr/lib/w32api -lpsapi ";
  }
  '';
}

sub install_type {'system'}

1;