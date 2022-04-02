"""
Note that this piece of code is (of course) only a hint
you are not required to use it
neither do you have to use any of the methods mentioned here
The code comes from
https://asyncio.readthedocs.io/en/latest/tcp_echo.html
To run:
1. start the echo_server.py first in a terminal
2. start the echo_client.py in another terminal
3. follow print-back instructions on client side until you quit
"""

import asyncio
import utilities
import time


class Client:
    def __init__(self, ip='127.0.0.1', server='', ID='client', message_max_length=1e6):
        """
        127.0.0.1 is the localhost
        port could be any port
        """
        self.ip = ip
        self.server = server
        self.ID = ID
        self.message_max_length = int(message_max_length)

    async def process_message(self, message: str):
        '''
        message: Format of WHATSAT - WHATSAT, name of another client, a radius (in kilometers) from the client
            (e.g., 10), and an upper bound on the amount of information to receive from Places data
            within that radius of the client (e.g., 5)
                 Format of IAMAT - IAMAT, name of client, lat-long, client time
        '''
        parsed_message = utilities.parse_message(message)
        match parsed_message[0]:
            case 'IAMAT':
                await self.tcp_IAMAT_client(parsed_message[2])
            case 'WHATSAT':
                await self.tcp_WHATSAT_client(parsed_message[1], parsed_message[2], parsed_message[3])
            case _:
                raise ValueError('Bad command')

    async def tcp_WHATSAT_client(self, client_ID: str, radius_bound: str, info_bound: str):
        """
        on client side send request for WHATSAT. Client asks for another client's location
        """
        port = utilities.server_ports_dict[self.server]
        reader, writer = await asyncio.open_connection(self.ip, port)

        # Build whole message
        message = f'WHATSAT {client_ID} {radius_bound} {info_bound}'
        print(f'{self.ID} send: {message!r}')
        writer.write(message.encode())

        # Wait for response. We know that the message will be one line
        data = await reader.read(self.message_max_length)
        print(f'{self.ID} received: {data.decode()!r}')

        print('close the socket')
        # The following lines closes the stream properly
        # If there is any warning, it's due to a bug o Python 3.8: https://bugs.python.org/issue38529
        # Please ignore it
        writer.close()

    async def tcp_IAMAT_client(self, location: str):
        """
        on client side send the message IAMAT
        """
        port = utilities.server_ports_dict[self.server]
        reader, writer = await asyncio.open_connection(self.ip, port)

        # Build time sent string
        time_nano_data = time.time_ns()
        time_sent = utilities.format_nano_time(time_nano_data)

        # Build whole message
        message = f'IAMAT {self.ID} {location} {time_sent}'
        print(f'{self.ID} send: {message!r}')
        writer.write(message.encode())

        # Wait for response. We know that the message will be one line
        data = await reader.read(self.message_max_length)
        print(f'{self.ID} received: {data.decode()!r}')

        print('close the socket')
        # The following lines closes the stream properly
        # If there is any warning, it's due to a bug o Python 3.8: https://bugs.python.org/issue38529
        # Please ignore it
        writer.close()

    def run_until_quit(self):
        # start the loop
        while True:
            # collect the message to send
            message = input("Please input an AT or WHATSAT command to send: ")
            if message in ['quit', 'exit', ':q', 'exit;', 'quit;', 'exit()', '(exit)']:
                break
            else:
                asyncio.run(self.process_message(message))


if __name__ == '__main__':
    client = Client(ID='kiwi.cs.ucla.edu', server='Juzang')  # using the default settings
    client.run_until_quit()
