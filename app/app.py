import logging
from django.http import HttpResponse
from django.conf import settings
from django.core.management import execute_from_command_line
from django.core.wsgi import get_wsgi_application
from django.urls import path
import sys

logging.basicConfig(level=logging.DEBUG)

settings.configure(
    DEBUG=True,
    ROOT_URLCONF='app',
    ALLOWED_HOSTS=['*'],
    INSTALLED_APPS=[
        'django.contrib.staticfiles',
    ],
)

def hello_world(request):
    logging.debug("Handling request to root route")
    return HttpResponse("Hello, World!")

urlpatterns = [
    path('', hello_world),
]

# Define the WSGI application for Gunicorn
application = get_wsgi_application()

if application == "app":
    logging.debug("Starting Django app")
    execute_from_command_line([sys.argv[0], 'runserver', '0.0.0.0:443'])