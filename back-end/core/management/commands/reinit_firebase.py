# core/management/commands/reinit_firebase.py
from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config

class Command(BaseCommand):
    help = 'Reinitialize Firebase connection after changing service account key'

    def handle(self, *args, **options):
        try:
            firebase_config.reinitialize()
            self.stdout.write(
                self.style.SUCCESS('Successfully reinitialized Firebase connection')
            )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Failed to reinitialize Firebase: {str(e)}')
            )