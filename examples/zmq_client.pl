use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus::Memory qw( malloc free );
use FFI::Platypus::Declare qw( pointer int string );

lib find_lib_or_exit lib => 'zmq';

attach zmq_init => [int] => pointer;
attach zmq_socket => [pointer, int] => pointer;
attach zmq_connect => [pointer, string] => int;
attach zmq_send => [pointer, pointer, int] => int;
attach zmq_msg_init_data => [pointer, string, int, pointer, pointer] => int;
attach zmq_msg_data => [pointer] => string;

# init zmq context
my $ctx = zmq_init(1);

# init zmq socket and bind
my $sock = zmq_socket($ctx, 3); # 3 is ZMQ_REQ
zmq_connect($sock, 'tcp://127.0.0.1:6666');

# send message to server
my $msg = malloc 40; # 40 is sizeof(zmq_msg_t);
zmq_msg_init_data($msg, 'some message', 4, undef, undef);

zmq_send($sock, $msg, 0);

free $msg;
