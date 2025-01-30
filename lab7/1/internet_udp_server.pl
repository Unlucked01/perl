use Socket;
$server_port = 1028;
socket(SERVER, PF_INET, SOCK_DGRAM, getprotobyname('udp')) or die "Could not create UDP server: $!";
bind(SERVER, sockaddr_in($server_port, INADDR_ANY)) or die "Can't bind: $!";
while (recv(SERVER, my $message, 1024, 0)) {
    print "Received: $message";
}
close(SERVER);
