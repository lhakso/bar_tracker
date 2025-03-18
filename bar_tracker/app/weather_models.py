from django.db import models

class CurrentWeather(models.Model):
    temperature = models.IntegerField(null=True)
    is_clear = models.BooleanField(default=False)
    is_clouds = models.BooleanField(default=False)
    is_rain = models.BooleanField(default=False)
    is_snow = models.BooleanField(default=False)
    is_thunderstorm = models.BooleanField(default=False)
    is_drizzle = models.BooleanField(default=False)
    is_mist = models.BooleanField(default=False)

    @classmethod
    def update_weather(cls, current_temp, current_weather):

        update_values = {
            'temperature': current_temp,
            'clear': False,
            'clouds': False, 
            'rain': False,
            'snow': False,
            'thunderstorm': False,
            'drizzle': False,
            'mist': False,
        }

        weather_key = current_weather.lower()

        if current_weather in update_values.keys():
            update_values[weather_key] = True

        else:
            print("unkown weather condition")

        obj, created = CurrentWeather.objects.update_or_create(
            id=1,
            defaults=update_values
        )
        return obj