import socketserver
import time
import select


class MyTCPHandler(socketserver.BaseRequestHandler):
    instances = set()

    """
    The request handler class for our server.

    It is instantiated once per connection to the server, and must
    override the handle() method to implement communication to the
    client.
    """

    def receive_command(self, command):
        if command == b"pulse_alpha" or b"pulse_beta":
            for instance in MyTCPHandler.instances:
                if instance != self:
                    instance.send_command(command)
        else:
            print("{}: Unknown command received: {}".format(self.ip, command))

    def send_command(self, command):
        self.commands_to_send.append(command)

    def handle(self):
        print("New client!")
        MyTCPHandler.instances.add(self)
        self.commands_to_send = []
        self.received_data = b""

        self.ip = self.client_address[0]

        try:
            while True:
                if self.commands_to_send:
                    self.request.sendall(self.commands_to_send.pop(0) + b"\n")

                else:
                    rlist, _, _ = select.select([self.request], [], [], 0.1)
                    if rlist:
                        new_data = self.request.recv(1024)
                        print("{}: Received command: {}".format(self.ip, new_data))
                        self.received_data += new_data

                        while True:
                            line_break = self.received_data.find(b"\n")
                            if line_break == -1:
                                break
                            command = self.received_data[:line_break]
                            self.received_data = self.received_data[
                                line_break + 1:]

                            if command == b"quit":
                                return
                            else:
                                self.receive_command(command)

        finally:
            MyTCPHandler.instances.remove(self)


def main():
    HOST, PORT = "0.0.0.0", 9000

    # Create the server, binding to everything on port 9000
    server = socketserver.ThreadingTCPServer((HOST, PORT), MyTCPHandler)
    # Activate the server; this will keep running until you
    # interrupt the program with Ctrl-C
    server.serve_forever()


if __name__ == "__main__":
    print("starting server")
    main()
