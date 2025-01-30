use Socket;
socket(SERVER, PF_UNIX, SOCK_DGRAM, 0) or die "Could not create UNIX UDP server: $!";
bind(SERVER, sockaddr_un('tmp_udp.tmp')) or die "Can't bind: $!";
while (recv(SERVER, my $message, 1024, 0)) {
    print "Received: $message\n";
}
close(SERVER);
