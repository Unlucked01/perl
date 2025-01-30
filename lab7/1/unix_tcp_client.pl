use Socket;
socket(CLIENT, PF_UNIX, SOCK_STREAM, 0);
connect(CLIENT, sockaddr_un('tmp.tmp')) or die "Can't connect to tmp.tmp: $!";
$message = "UNIX socket TCP\n";
print CLIENT $message;
close(CLIENT);
