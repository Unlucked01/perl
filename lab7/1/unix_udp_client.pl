use Socket;
socket(CLIENT, PF_UNIX, SOCK_DGRAM, 0) or die "Could not create UNIX UDP client: $!";
send(CLIENT, "UNIX socket UDP\n", 0, sockaddr_un('tmp_udp.tmp'));
close(CLIENT);
