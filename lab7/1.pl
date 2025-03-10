#!/usr/bin/perl

use Socket;
use IO::Handle;
use threads;


sub server_inet_tcp {
    socket(SOCKET, AF_INET, SOCK_STREAM, getprotobyname('tcp')) or die "socket: $!";
    setsockopt(SOCKET, SOL_SOCKET, SO_REUSEADDR, 1);
    bind(SOCKET, pack_sockaddr_in(8099, inet_aton('127.0.0.1'))) or die "bind: $!";
    listen(SOCKET, SOMAXCONN) or die "listen: $!";
    
    while ($new_socket = accept(NEW_SOCKET, SOCKET)) {
        while (defined ($message = <NEW_SOCKET>)) {
            if ($message eq "exit\n") {
                close(NEW_SOCKET);
                close(SOCKET);
                return;
            }
            print "Received: " . $message;
        }
        close(NEW_SOCKET);
    }
    close(SOCKET);
}

sub server_inet_udp {
    socket(SOCKET, PF_INET, SOCK_DGRAM, getprotobyname('udp')) or die "socket: $!";
    bind(SOCKET, pack_sockaddr_in(8099, INADDR_ANY)) or die "bind: $!";
    
    while (1) {
        recv(SOCKET, my $buffer, 1024, 0);
        if ($buffer eq "exit\n") {
            close(SOCKET);
            return;
        }
        print "Received: " . $buffer;
    }
    close(SOCKET);
}

sub server_unix_tcp {
    socket(SOCKET, PF_UNIX, SOCK_STREAM, 0) or die "socket: $!";
    unlink('/tmp/my_unix_socket');
    bind(SOCKET, pack_sockaddr_un('/tmp/my_unix_socket')) or die "bind: $!";
    listen(SOCKET, SOMAXCONN) or die "listen: $!";
    
    while ($new_socket = accept(NEW_SOCKET, SOCKET)) {
        while (defined ($message = <NEW_SOCKET>)) {
            if ($message eq "exit\n") {
                close(NEW_SOCKET);
                close(SOCKET);
                return;
            }
            print "Received: " . $message;
        }
        close(NEW_SOCKET);
    }
    close(SOCKET);
}

sub server_unix_udp {
    socket(SOCKET, PF_UNIX, SOCK_DGRAM, 0) or die "socket: $!";
    unlink('/tmp/my_unix_socket');
    bind(SOCKET, pack_sockaddr_un('/tmp/my_unix_socket')) or die "bind: $!";
    
    while (1) {
        recv(SOCKET, my $buffer, 1024, 0);
        if ($buffer eq "exit\n") {
            close(SOCKET);
            return;
        }
        print "Received: " . $buffer;
    }
    close(SOCKET);
}

sub client_inet_tcp {
    socket(SOCKET, AF_INET, SOCK_STREAM, getprotobyname('tcp')) or die "socket: $!";
    connect(SOCKET, pack_sockaddr_in(8099, inet_aton('127.0.0.1'))) or die "connect: $!";
    my $exitFlag = 1;
    
    while ($exitFlag) {
        print "Message: ";
        my $line = <STDIN>;
        chomp($line);
        $line .= "\n";

        send(SOCKET, $line, 0);
        if ($line eq "exit\n") {
            $exitFlag = 0;
        }
    }
    close(SOCKET);
}

sub client_inet_udp {
    socket(SOCKET, PF_INET, SOCK_DGRAM, getprotobyname('udp')) or die "socket: $!";
    my $server_addr = pack_sockaddr_in(8099, inet_aton('127.0.0.1'));
    
    my $exitFlag = 1;
    while ($exitFlag) {
        print "Message: ";
        my $line = <STDIN>;
        chomp($line);
        $line .= "\n";
        
        send(SOCKET, $line, 0, $server_addr) or die "send: $!";
        
        if ($line eq "exit\n") {
            $exitFlag = 0;
        }
    }
    close(SOCKET);
}

sub client_unix_tcp {
    my $socket_path = '/tmp/my_unix_socket';
    socket(SOCKET, PF_UNIX, SOCK_STREAM, 0) or die "socket: $!";
    connect(SOCKET, pack_sockaddr_un($socket_path)) or die "connect: $!";
    
    my $exitFlag = 1;
    while ($exitFlag) {
        print "Message: ";
        my $line = <STDIN>;
        chomp($line);
        $line .= "\n";

        send(SOCKET, $line, 0);
        if ($line eq "exit\n") {
            $exitFlag = 0;
        }
    }
    close(SOCKET);
}

sub client_unix_udp {
    my $socket_path = '/tmp/my_unix_socket';
    socket(SOCKET, PF_UNIX, SOCK_DGRAM, 0) or die "socket: $!";
    my $exitFlag = 1;
    
    while ($exitFlag) {
        print "Message: ";
        my $line = <STDIN>;
        chomp($line);
        $line .= "\n";
        
        send(SOCKET, $line, 0, pack_sockaddr_un($socket_path));
        if ($line eq "exit\n") {
            $exitFlag = 0;
        }
    }
    close(SOCKET);
}

if (@ARGV && ($ARGV[0] eq "client" || $ARGV[0] eq "server")) {
    my $domain = $ARGV[1] || "1";  # Default to INET
    my $proto = $ARGV[2] || "1";   # Default to TCP
    
    if ($ARGV[0] eq "client") {
        if ($domain eq "1") {
            if ($proto eq "1") {
                print "Client with TCP/INET has started\n\n";
                client_inet_tcp();
            } else {
                print "Client with UDP/INET has started\n\n";
                client_inet_udp();
            }
        } else {
            if ($proto eq "1") {
                print "Client with TCP/UNIX has started\n\n";
                client_unix_tcp();
            } else {
                print "Client with UDP/UNIX has started\n\n";
                client_unix_udp();
            }
        }
    } else {
        if ($domain eq "1") {
            if ($proto eq "1") {
                print "Server with TCP/INET has started\n\n";
                server_inet_tcp();
            } else {
                print "Server with UDP/INET has started\n\n";
                server_inet_udp();
            }
        } else {
            if ($proto eq "1") {
                print "Server with TCP/UNIX has started\n\n";
                server_unix_tcp();
            } else {
                print "Server with UDP/UNIX has started\n\n";
                server_unix_udp();
            }
        }
    }
    exit;
}

print "Enter the domain type: PF_INET (1) or PF_UNIX (2): ";
my $domain = <STDIN>;
chomp $domain;
print "Enter the protocol: tcp (1) or udp (2): ";
my $proto = <STDIN>;
chomp $proto;
print "\n\n";
print "Type \"exit\" to stop the program\n\n";

if ($domain && $proto) {
    if ($^O eq 'darwin') {  # macOS
        my $current_dir = `pwd`;
        chomp($current_dir);
        
        my $apple_script = <<APPLESCRIPT;
tell application "Terminal"
    do script "cd $current_dir && perl $0 server $domain $proto"
    delay 3
    do script "cd $current_dir && perl $0 client $domain $proto"
    activate
end tell
APPLESCRIPT

        open(my $fh, '>', '/tmp/terminal_script.scpt') or die "Could not open file: $!";
        print $fh $apple_script;
        close $fh;
        
        system("osascript /tmp/terminal_script.scpt");
        unlink('/tmp/terminal_script.scpt');  # Clean up
        
        print "Server and client windows should be open now.\n";
    } else {
        print "Separate terminal functionality is only implemented for macOS.\n";
        print "Please run the client and server manually:\n";
        print "perl $0 server\n";
        print "perl $0 client\n";
    }
}