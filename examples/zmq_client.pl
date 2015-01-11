use strict;
use warnings;
use FFI::CheckLib;
use FFI::Platypus::Memory qw( malloc free );
use FFI::Platypus::Declare qw( pointer int string );

lib find_lib_or_exit lib => 'zmq';

function zmq_init => [int] => pointer;
function zmq_socket => [pointer, int] => pointer;
function zmq_connect => [pointer, string] => int;
function zmq_send => [pointer, pointer, int] => int;
function zmq_msg_init_data => [pointer, string, int, pointer, pointer] => int;
function zmq_msg_data => [pointer] => string;

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
