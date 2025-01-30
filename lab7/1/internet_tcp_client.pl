use Socket;
$remote_port = 1027;
$remote_host = 'localhost';
socket(CLIENT, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
$internet_addr = inet_aton($remote_host) or die "Couldn't build Internet address for $remote_host";
connect(CLIENT, sockaddr_in($remote_port, $internet_addr)) or die "Can't connect to $remote_host: $!";
$message = "Inet socket TCP\n";
print CLIENT $message;
close(CLIENT);
