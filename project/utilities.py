from datetime import date
import re
import datetime

server_ports_dict = { 'Juzang': 10156, 'Bernard': 10157, 'Jaquez': 10158, 'Johnson': 10159, 'Clark': 10160 }

def parse_message(message: str):
    '''
        This should strip out all whitespace from a message.
        message: string that contains the message
        returns: message as an array with no whitespace.
    '''
    return message.split()


def convert_time(time_of_message: str):
    '''
    time_of_message: seconds and nanoseconds since 1970-01-01 00:00:00 UTC
    '''
    nanoseconds = time_of_message[-3:]
    print(time_of_message[:-3])
    converted_date = datetime.datetime.fromtimestamp(float(time_of_message[:-3]))
    return converted_date.strftime('%Y-%m-%d %H:%M:%S.%f') + nanoseconds


def format_nano_time(time_nano_data: int):
    '''
    Takes nanoseconds and returns seconds.nanoseconds
    '''
    time_second_data = time_nano_data / 1.0e-9
    time_sent = f'{time_second_data}'
    return time_sent

KEY = 'AIzaSyA_4YaUhU0C2SHbZ_AfjLShuNoSEliPwRc'
def construct_http(lat_long: str, km_radius='50'):
    '''
    lat_long: coordinates formatted as latitude-longitude
    km_radius: radius in kilometers as a string. Places API default is 50km.
        Set as default here for convenience.
    '''
    m_radius = int(km_radius) * 1000
    radius = f'{m_radius}'
    latitude, longitude = re.findall('[-+]\d+\.\d+|[-+]\d+', lat_long)
    location = f'{latitude},{longitude}'
    url = f'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
    return (url, location, radius, KEY)

def format_json(response):
    formatted_response, _ = re.subn('(\n+)\n', '\n', response)
    formatted_response = formatted_response.strip()
    return formatted_response + '\n\n'
