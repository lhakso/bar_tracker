from django.core.management.base import BaseCommand
import requests
from app.weather_models import CurrentWeather
from decouple import config

class Command(BaseCommand):

    help = 'Updates weather information from external API'

    def handle(self, *args, **options):

        api_key = config("OPEN_WEATHER_API_KEY")
        city = "Charlottesville,US"

        # Make API request to OpenWeatherMap
        base_url = "https://api.openweathermap.org/data/2.5/weather"
        params = {
            'q': city,
            'appid': api_key,
            'units': 'imperial'
        }

        response = requests.get(base_url, params=params)
        data = response.json()
        
        feels_like_temp = int(data['main']['feels_like'])
        weather = data['weather'][0]['main'].lower()
        CurrentWeather.update_weather(current_temp=feels_like_temp, current_weather=weather)
