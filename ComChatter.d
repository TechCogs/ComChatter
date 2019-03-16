/***********************************************************************
 * ComChatter, A very simple command line IRC client                   *
 * Copyright (C) 2019 TechCogs                                         *
 * Licensed under the GNU GPLv3                                        *
 *                                                                     *
 * @TechCogs on Twitter and Github                                     *
 * https://github.com/TechCogs/ComChatter                              *
 ***********************************************************************/

import std.stdio;
import std.string;
import std.socket;

void main() {
  Socket sock = new TcpSocket();
  try {
    auto address = getAddress("irc.freenode.org", 6667);
    sock.connect(address[0]);

    sock.send("NICK ReallyNThingy\r\n");
    sock.send("USER ReallyNThingy * * :Thingy\r\n");

    while(true) {
      char[] input;
      char[1] buf;

      while(buf[0] != '\n') {
        sock.receive(buf);
        input ~= buf;
      }

      if (input.startsWith("PING")) {
        sock.send("PONG\r\n");
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
