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
import std.concurrency;
import std.conv;
import std.socket;
import core.thread;

enum DEFAULT_USER = "ThingyUser";
enum DEFAULT_PORT = "6667";
enum DEFAULT_SERVER = "irc.freenode.org";
enum VERSION = 0.2;

void main() {
  writeln("ComChatter v", VERSION);
  writeln("A simple IRC client");
  writeln("Copyright (C) 2019 TechCogs");
  writeln("https://github.com/TechCogs/ComChatter");
  writeln("");

  string user;
  string server;
  string port;
  string channel;

  bool connected = false;

  writef("User name [%s]>", DEFAULT_USER);
  user = strip(readln());
  writef("IRC Server [%s]>", DEFAULT_SERVER);
  server = strip(readln());
  writef("Port [%s]>", DEFAULT_PORT);
  port = strip(readln());
  writeln();

  if (user == "") user = DEFAULT_USER;
  if (server == "") server = DEFAULT_SERVER;
  if (port == "") port = DEFAULT_PORT;


  Socket sock = new TcpSocket();
  try {
    auto address = getAddress(server, to!ushort(port));
    sock.connect(address[0]);

    string userNickData = format("NICK %s\r\n", user);
    string userUserData = format("USER %s * * :%s\r\n", user, user);

    sock.send(userNickData);
    sock.send(userUserData);
    sock.blocking = false;

    bool program = true;

    auto inputWorker = spawn(&getInput);

    while(program) {
      char[] input;
      char[1] buf;

      while(buf[0] != '\n') {
        long c = sock.receive(buf);
        if (c == -1) {
          receiveTimeout(50.msecs,
            (string s) {
              s = strip(s);
              if (s == "!quit") {
                sock.send("QUIT\r\n");
                program = false;
              }
              else parseCommands(s, sock, channel);
              /*else {
                sock.send(s ~ "\r\n");
              }*/
            });
          Thread.sleep(2.seconds);
          continue;
        }
        input ~= buf;
      }

      if (input.startsWith("PING")) {
        sock.send("PONG\r\n");
      }

      writeln(formatText(input));

    }
  }
  catch (Exception e) {
    writeln(e);
  }
  scope (exit) {
    sock.close();
    thread_joinAll();
  }

}

string formatText(in char[] text) {
  string words = strip(to!string(text));
  string[] s = words.split(":");
  if (s.length > 2) {
    return s[2];
  }
  else {
    return s[1];
  }
}

void getInput() {
  while (true) {
    write(">");
    string s = strip(readln());
    ownerTid.send(s ~ "\r\n");
    if (s == "!quit") {
      break;
    }
  }
}

void parseCommands(string command, ref Socket sock, ref string channel) {
  if (command.startsWith("/join")) {
    command = command.strip("/join ");
    if (channel != "") {
      sock.send("PART " ~ channel ~ "\r\n");
    }
    channel = command;
    sock.send("JOIN " ~ command ~ "\r\n");
  }
  if (command.startsWith("/raw")) {
    command = command.strip("/raw ");
    sock.send(command ~ "\r\n");
  }
  else {
    sock.send("PRIVMSG " ~ channel ~ " :" ~ command ~ "\r\n");
  }
}
