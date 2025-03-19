from django.db import models

class CurrentWeather(models.Model):
    temperature = models.IntegerField(null=True)
    weather_string = models.CharField(blank=True, null=True)
    clear = models.BooleanField(default=False)
    clouds = models.BooleanField(default=False)
    rain = models.BooleanField(default=False)
    snow = models.BooleanField(default=False)
    thunderstorm = models.BooleanField(default=False)
    drizzle = models.BooleanField(default=False)
    mist = models.BooleanField(default=False)

    @classmethod
    def update_weather(cls, current_temp, current_weather):

        update_values = {
            'temperature': current_temp,
            'weather_string': current_weather,
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