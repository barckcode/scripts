import requests, json

def main():
    try:
        response = requests.get('https://ifconfig.co/json').json()

        data = {
            'Public IP': response['ip'],
            'Country': response['country'],
            'Region Name': response['region_name'],
            'City': response['city'],
            'Latitude': response['latitude'],
            'Longitude': response['longitude'],
        }

        print('-' * 40)
        print('🧐 Datos obtenidos de tu IP Publica:')
        print('-' * 40)
        for llaves, valores in data.items():
            print(f'➭ {llaves}: {valores}')

    except:
        print('ERROR: La peticion ha sido erronea.')


if __name__ == "__main__":
    main()