use Socket;

$server_port = 1027;
socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
bind(SERVER, sockaddr_in($server_port, INADDR_ANY)) or die "Can't create server: $!";
listen(SERVER, SOMAXCONN) or die "Can't listen this socket: $!";
for (; accept(CLIENT, SERVER); close(CLIENT)) {
    while (defined($message = <CLIENT>)) {
        print "Received: $message";
    }
}
close(SERVER);
