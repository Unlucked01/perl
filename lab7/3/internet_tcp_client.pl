use IO::Socket;
$remote_host = 'localhost';
$remote_port = 1029;
$client = IO::Socket::INET->new(
    PeerAddr => $remote_host,
    PeerPort => $remote_port,
    Proto    => 'tcp',
    Type     => SOCK_STREAM
) or die "Can't connect to $remote_host";

print "Connected to server. Type messages to send.\n";
while (my $message = <STDIN>) {
    print $client $message;
    my $response = <$client>;
    print $response;
}
close($client);
