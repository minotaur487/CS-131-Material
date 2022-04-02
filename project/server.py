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
import argparse
import time
import aiohttp
import utilities
import sys
import logging
import json

# talks bidirectionally
server_neighbors = {
    'Juzang': ['Johnson', 'Bernard', 'Clark'],
    'Bernard': ['Juzang', 'Jaquez', 'Johnson'],
    'Clark': ['Jaquez', 'Juzang'],
    'Jaquez': ['Clark', 'Bernard'],
    'Johnson': ['Juzang', 'Bernard']
}

class Server:
    def __init__(self, name, ip='127.0.0.1', message_max_length=1e6):
        self.name = name
        self.ip = ip
        self.port = utilities.server_ports_dict[name]
        # self.message_max_length = int(message_max_length)
        self.location_dict = dict()
        self.client_dict = dict()
        logging.info(f'LOG FILE FOR SERVER {name}')

    async def propagate_info(self, message):
        for neighbor in server_neighbors[self.name]:
            try:
                _, writer = await asyncio.open_connection(self.ip, utilities.server_ports_dict[neighbor])
                logging.info(f'{self.name} sent to {neighbor}: {message!r}')
                writer.write(message.encode())
                await writer.drain()
                writer.close()
                await writer.wait_closed()
            except:
                logging.info(f'Could not successfully connect to server {neighbor}.')

    async def handle_WHATSAT(self, parsed_message):
        '''
        Server acts as client to Google Places server

        parsed_message: [WHATSAT, name of another client, a radius (in kilometers) from the client
            (e.g., 10), and an upper bound on the amount of information to receive from Places data
            within that radius of the client (e.g., 5)]
        '''
        radius_boundary = int(parsed_message[2])
        info_boundary = int(parsed_message[3])
        if radius_boundary > 50 or info_boundary > 20:
            raise ValueError(f'Radius can be at most 50km and amount of information can at most be 20 items.')

        # Gets information for http request
        logging.info(f'Attempting to retrieve places around {parsed_message[1]}.')

        url, location, radius, key = utilities.construct_http(self.location_dict[parsed_message[1]], radius_boundary)
        expect = f'{url}?location={location}&radius={radius}&key={key}'
        params = { 'location': location, 'radius': radius, 'key': key }
        async with aiohttp.ClientSession() as session:
            # async with session.get(url, params=params) as resp:
            async with session.get(expect) as resp:
                response = await resp.text()
        

        # Handle when amount of information desired is less than default
        resp_as_json = json.loads(response)
        logging.info(f'Successfully retrieved {len(resp_as_json["results"])} from query.')
        if len(resp_as_json['results']) > info_boundary:
            resp_as_json['results'] = resp_as_json['results'][:info_boundary]
            response = json.dumps(resp_as_json, indent=4)
            assert len(resp_as_json['results']) == info_boundary
        
        formatted_response = utilities.format_json(response)
        return f'{self.client_dict[parsed_message[1]][1]}\n{formatted_response}'

    async def handle_IAMAT(self, parsed_message):
        '''
        parsed_message: [IAMAT, name of client, lat-long, client time]

        Return: Response message. Side effect is appending to dict of client responses, where latest
            message is at the end of the list
            [AT, server name, server time elapsed, name of client, lat-long, client time]
        '''
        client_name = parsed_message[1]
        location = parsed_message[2]
        client_time = float(parsed_message[3])

        # Construct elapsed time
        nano_time = client_time * 1.0e9
        time_elapsed = time.time_ns() - nano_time
        print(time_elapsed)
        time_elapsed = time_elapsed * 1.0e-9
        print(time_elapsed)

        # Construct response
        response = f'AT {self.name} {"+" if time_elapsed > 0 else ""}{time_elapsed} {client_name} {location} {client_time}'
        
        # Update location dictionary
        self.location_dict[client_name] = location

        # Update dictionary of client responses and propagate
        self.client_dict[parsed_message[1]] = (client_time, response)
        await self.propagate_info(response)
        
        return response
    
    async def handle_AT(self, message, parsed_message):
        '''
        message: str(AT, server that processed query, time elapsed, name of client, lat-long, client time)
        parsed_message: [AT, server that processed query, time elapsed, name of client, lat-long, client time]
        '''
        client_name = parsed_message[3]
        client_time = float(parsed_message[5])
        location = parsed_message[4]

        if (self.client_dict.get(client_name) is None):
            logging.info(f'Adding new data for client {client_name} and propagating that data.')
            self.client_dict[client_name] = (client_time, message)
            self.location_dict[client_name] = location
            await self.propagate_info(message)
        elif (self.client_dict[client_name][1] != message and client_time > self.client_dict[client_name][0]):
            logging.info(f'Updating data for client {client_name} and propagating that data.')
            self.client_dict[client_name] = (client_time, message)
            self.location_dict[client_name] = location
            await self.propagate_info(message)
        else:
            return f'Stopped propagating. Message has already been received'
        return None     # Server didn't receive anything back.

    async def process_message(self, message):
        parsed_message = utilities.parse_message(message)

        # Return invalid command response.
        if (len(parsed_message) != 4 and len(parsed_message) != 6):
            return f'? {message}'

        # pattern matching doesn't allow for dropping through cases
        match parsed_message[0]:
            case 'IAMAT':
                return await self.handle_IAMAT(parsed_message)
            case 'WHATSAT':
                return await self.handle_WHATSAT(parsed_message)
            # Case where message is from server propagation
            case 'AT':
                return await self.handle_AT(message, parsed_message)
            case _:
                return f'? {message}'

    async def handle_request(self, reader, writer):
        """
        on server side
        """
        while not reader.at_eof():
            # Receive request
            data = await reader.readline()
            message = data.decode()
            if message == '':
                continue
            addr = writer.get_extra_info('peername')
            logging.info(f'{self.name} received {message} from {addr}')

            # Process message
            sendback_message = await self.process_message(message)
            if sendback_message is not None:
                logging.info(f'{self.name} sent: {sendback_message}')
                # Send response
                writer.write(sendback_message.encode())
                await writer.drain()

        logging.info(f'Close the client socket.')
        writer.close()
        await writer.wait_closed()

    async def run_forever(self):
        server = await asyncio.start_server(self.handle_request, self.ip, self.port)

        # Serve requests until Ctrl+C is pressed
        logging.info(f'Starting server: {self.name}')
        async with server:
            await server.serve_forever()

        # Close the server
        logging.info(f'Shutting down {self.name}')
        server.close()


def main():
    parser = argparse.ArgumentParser('Proxy Herd Prototype with asyncio')
    parser.add_argument('server_name', type=str,
                        help='Required server name input')
    args = parser.parse_args()

    if args.server_name not in server_neighbors.keys():
        print(f'Invalid server name: {args.server_name}. Try Juzang, Bernard, Jaquez, Johnson, or Clark.')
        sys.exit()

    logging.basicConfig(filename=f'server_{args.server_name}.log',
                        filemode='w+',
                        level=logging.INFO,
                        format='%(levelname)s: %(message)s')

    server = Server(args.server_name)
    try:
        asyncio.run(server.run_forever())
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
