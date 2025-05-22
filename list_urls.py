import os
import django
from django.urls import get_resolver

# Initialise Django correctement
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "restaurant_system.settings")
django.setup()

def list_urls():
    resolver = get_resolver()
    url_patterns = resolver.url_patterns

    def extract_patterns(patterns, prefix=''):
        for pattern in patterns:
            if hasattr(pattern, 'url_patterns'):
                # C'est un include()
                yield from extract_patterns(pattern.url_patterns, prefix + str(pattern.pattern))
            else:
                # C'est une vue normale
                yield prefix + str(pattern.pattern), pattern.callback.__module__, pattern.callback.__name__

    for url, module, view in extract_patterns(url_patterns):
        print(f"{url:60} --> {module}.{view}")

if __name__ == "__main__":
    list_urls()
