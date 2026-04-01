# Dumiya Livreur App - Configuré

Cette version est déjà configurée pour :

- URL Odoo : `https://microfinance-rdc.online`
- Base de données : `finance`

## Endpoints utilisés
- `/dumiya/mobile/login`
- `/dumiya/mobile/deliveries`
- `/dumiya/mobile/delivery/<id>`
- `/dumiya/mobile/delivery/<id>/start`
- `/dumiya/mobile/pos/list`
- `/dumiya/mobile/delivery/<id>/proof`

## Build GitHub Actions
Le workflow `.github/workflows/android.yml` :
- installe Flutter
- régénère le squelette Android avec `flutter create . --platforms=android`
- construit l'APK release
- publie l'APK comme artifact GitHub

## Important
L'utilisateur mobile doit être le même que le champ `Livreur` sur la mission Dumiya, puisque la V3 filtre les missions par `driver_id = request.env.user.id`.

## Build local
```bash
flutter pub get
flutter create . --platforms=android --org com.locintel.dumiya --project-name dumiya_livreur_app
flutter pub get
flutter build apk --release
```

## Option GitHub variables
Tu peux laisser le projet tel quel, ou définir :
- `DUMIYA_BASE_URL`
- `DUMIYA_DB`

Si rien n'est défini dans GitHub, le workflow utilisera déjà :
- `https://microfinance-rdc.online`
- `finance`
