# Dumiya Livreur App - Version corrigée

Configuration intégrée :
- URL serveur : `https://microfinance-rdc.online`
- Base Odoo : `finance`

Corrections incluses :
- URL figée dans `AppConfig`
- suppression de l'usage des `dart-define`
- normalisation de l'URL dans Dio
- messages d'erreur réseau plus clairs
- affichage du serveur et de la base sur l'écran de connexion
- workflow GitHub qui génère Android puis force les permissions réseau

## Build GitHub
1. pousse le projet dans GitHub
2. ouvre l'onglet **Actions**
3. lance **Build Android APK**
4. télécharge l'artifact `dumiya-livreur-apk`
5. désinstalle l'ancienne APK avant d'installer la nouvelle
