use IO::Socket;
unlink 'tmp.tmp';
$server = IO::Socket::UNIX->new(
    Local  => 'tmp.tmp',
    Listen => 15
) or die "Can't create UNIX TCP server";
while ($client = $server->accept()) {
    print <$client>;
    close($client);
}
close($server);
