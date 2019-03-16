import std.stdio;
import std.socket;

void main() {
  Socket sock = new TcpSocket();
  try {
    auto address = getAddress("irc.freenode.org", 6667);
    sock.connect(address[0]);

    sock.send("NICK Thingy\r\n");
    sock.send("USER Thingy * * :Thingy\r\n");

    while(true) {
      char[] input;
      char[1] buf;

      while(buf[0] != '\n') {
        sock.receive(buf);
        input ~= buf;
      }

      write(input);

    }
  }
  catch (Exception e) {
    writeln(e.stringof);
  }
  scope (exit) {
    sock.close();
  }
}
