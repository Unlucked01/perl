use Socket;
socket(SERVER, PF_UNIX, SOCK_STREAM, 0);
setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
bind(SERVER, sockaddr_un('tmp.tmp')) or die "Can't create server: $!";
listen(SERVER, SOMAXCONN) or die "Can't listen this socket: $!";
for (; accept(CLIENT, SERVER); close(CLIENT)) {
    while (defined($message = <CLIENT>)) {
        print $message;
    }
}
close(SERVER);
