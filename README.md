# SupMag

Gestion multi-magasins (10 supermarchés) pour la vente et le stock de
produits de première nécessité en Côte d'Ivoire. Une seule base de code
Flutter, deux cibles : **Windows** (back-office complet) et **Android**
(caisse mobile, inventaire à la douchette, vue gérant).

## Stack

- Flutter (Dart), `provider` pour l'état applicatif.
- **Firestore** (`cloud_firestore`) comme backend partagé — les 10 magasins
  et tous les appareils Windows/Android lisent et écrivent dans le même
  projet Firebase (`gestentreprise-66a68`), avec le cache/la file d'attente
  hors-ligne de Firestore comme mécanisme de synchronisation (voir plus
  bas).
- Préférences **locales par terminal** (`shared_preferences`) pour le
  magasin actif, la variante de caisse et le mode hors-ligne de CE poste —
  volontairement hors de Firestore pour ne pas qu'un poste impose son choix
  d'écran aux autres.
- Police Source Serif 4 embarquée (`assets/fonts/`).

## ⚠️ À finir avant de lancer l'app

Le code est prêt côté Dart, mais `lib/firebase_options.dart` contient des
valeurs `REPLACE_ME` : générer la vraie configuration nécessite une
connexion Google interactive que je n'ai pas pu faire depuis la session qui
a écrit ce code. Pour finir la connexion :

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=gestentreprise-66a68 --platforms=android,windows
```

Cette commande enregistre une appli Android et une appli Windows sous le
projet Firebase `gestentreprise-66a68` et réécrit `lib/firebase_options.dart`
avec les vraies valeurs. Assurez-vous aussi que **Cloud Firestore** est
activé sur ce projet (console Firebase → Firestore Database → Créer une
base de données) et posez des [règles de sécurité](https://firebase.google.com/docs/firestore/security/get-started)
adaptées avant toute mise en production (le mode test par défaut expire
sous 30 jours et n'authentifie personne).

**Index Firestore requis** : les écrans Tableau de bord et Rapports
interrogent `collectionGroup('lines')` filtré sur `created_at` — la
première exécution en conditions réelles renverra une erreur avec un lien
direct pour créer l'index composite manquant ; suivez ce lien une fois,
Firestore s'en souvient ensuite.

## État actuel

Il n'y a pas encore d'authentification (n'importe qui avec la config
Firebase peut lire/écrire) — à ajouter avant un déploiement réel, avec des
règles Firestore qui vérifient l'identité et le rôle de l'utilisateur.

## Écrans

**Windows** (barre latérale) : Tableau de bord, Caisse (variantes grille
tactile / scan + clavier, au choix par poste), Stock & inventaire,
Réception de marchandises, Transferts entre magasins, Produits & prix,
Rapports de ventes, Fournisseurs & commandes, Utilisateurs & rôles.

**Android** (navigation basse) : Caisse mobile, Inventaire à la douchette,
Vue gérant ("Ma journée").

## Lancer le projet

```bash
flutter pub get
flutter run -d windows   # ou -d <device-android>
```

## Tests

```bash
flutter test
```

Utilise `fake_cloud_firestore` (base en mémoire, pas besoin du vrai projet
Firebase) et un `SharedPreferences` mocké. Couvre le boot de l'application,
la navigation entre tous les écrans Windows, les deux variantes de caisse +
encaissement, la création d'un transfert, l'ajout d'un produit, la
génération de bons de commande, et les trois écrans Android.
