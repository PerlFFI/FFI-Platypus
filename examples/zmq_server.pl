use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus::Memory qw( malloc free );
use FFI::Platypus::Declare qw( opaque int string );

lib find_lib_or_exit lib => 'zmq';

attach zmq_init => [int] => opaque;
attach zmq_socket => [opaque, int] => opaque;
attach zmq_bind => [opaque, string] => int;
attach zmq_recv => [opaque, opaque, int] => int;
attach zmq_msg_init => [opaque] => int;
attach zmq_msg_data => [opaque] => string;

# init zmq context
my $ctx = zmq_init(1);

# init zmq socket and bind
my $sock = zmq_socket($ctx, 4); # 4 is ZMQ_REP
zmq_bind($sock, 'tcp://127.0.0.1:6666');

# receive message from client
my $msg = malloc 40; # 40 is sizeof(zmq_msg_t)
zmq_msg_init($msg);

zmq_recv($sock, $msg, 0);
print zmq_msg_data($msg), "\n";

free $msg;
