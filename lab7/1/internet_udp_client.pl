use Socket;

$remote_port = 1028;
$remote_host = 'localhost';
socket(CLIENT, PF_INET, SOCK_DGRAM, getprotobyname('udp')) or die "Could not create UDP client: $!";
$internet_addr = inet_aton($remote_host) or die "Couldn't build Internet address for $remote_host";
send(CLIENT, "Inet socket UDP\n", 0, sockaddr_in($remote_port, $internet_addr));
close(CLIENT);
