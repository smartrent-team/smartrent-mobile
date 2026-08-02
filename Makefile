run:
	flutter run --dart-define-from-file=config.json

dev:
	flutter run --dart-define-from-file=config.json

release:
	flutter run --release --dart-define-from-file=config.json

build-apk:
	flutter build apk --dart-define-from-file=config.json

clean:
	flutter clean && flutter pub get
