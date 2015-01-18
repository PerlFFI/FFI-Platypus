use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus::Memory qw( malloc free );
use FFI::Platypus::Declare qw( pointer int string );

lib find_lib_or_exit lib => 'zmq';

attach zmq_init => [int] => pointer;
attach zmq_socket => [pointer, int] => pointer;
attach zmq_bind => [pointer, string] => int;
attach zmq_recv => [pointer, pointer, int] => int;
attach zmq_msg_init => [pointer] => int;
attach zmq_msg_data => [pointer] => string;

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
