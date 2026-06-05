# Déploiement Cloudflare Pages

Cette version utilise Cloudflare Pages pour l'app Flutter Web et Cloudflare Pages Functions pour l'API Battle.net.

## URLs à autoriser côté Battle.net

Dans le portail développeur Battle.net, ajoute au minimum :

- `https://wow100.pages.dev/callback`
- `https://wow100.cosmos-lty.fr/callback`
- `http://localhost:8788/callback` pour tester via Wrangler en local

Si tu utilises un domaine custom, ajoute aussi :

- `https://ton-domaine/callback`

## DNS recommandé avec OVH conservé

Tu peux garder OVH comme gestionnaire DNS principal pour `cosmos-lty.fr`.

Dans ce mode, ne remplace pas les serveurs DNS OVH par ceux de Cloudflare, et ne pointe jamais un CNAME vers `ed.ns.cloudflare.com` ou `suzanne.ns.cloudflare.com`. Ces valeurs sont des serveurs de noms, pas des cibles de site.

Pour `wow100.cosmos-lty.fr` :

1. Dans Cloudflare Pages, ajoute le domaine custom `wow100.cosmos-lty.fr` au projet Pages `wow100`.
2. Cloudflare te donnera une cible CNAME, généralement proche de `wow100.pages.dev`.
3. Dans la zone DNS OVH, crée ou modifie seulement :

```text
wow100.cosmos-lty.fr.  CNAME  wow100.pages.dev.
```

Garde tes autres entrées OVH existantes :

- `weekendly.cosmos-lty.fr` vers Vercel
- `api.weekendly.cosmos-lty.fr` vers Vercel
- `mail`, `imap`, `smtp`, `pop3`, `MX`, `TXT`, `DKIM`

Cette approche permet d'utiliser Cloudflare uniquement pour WoW100%, sans déplacer tout le domaine.

## Secrets Cloudflare

Si le projet Pages n'existe pas encore :

```bash
npx wrangler pages project create wow100 --production-branch main
```

Depuis ce dossier `cloudflare/`, configure les secrets :

```bash
npx wrangler pages secret put BATTLENET_CLIENT_ID --project-name wow100
npx wrangler pages secret put BATTLENET_CLIENT_SECRET --project-name wow100
npx wrangler pages secret put BATTLENET_ALLOWED_REDIRECT_URIS --project-name wow100
```

Exemple pour `BATTLENET_ALLOWED_REDIRECT_URIS` :

```text
http://localhost:8788/callback,http://localhost:8080/callback,https://wow100.pages.dev/callback,https://wow100.cosmos-lty.fr/callback
```

## Test local Cloudflare

Depuis la racine du projet :

```bash
flutter build web --debug --dart-define=WOW100_API_BASE_URL=/api
```

Puis depuis ce dossier `cloudflare/` :

```bash
npx wrangler pages dev ../build/web
```

L'app sera disponible sur `http://localhost:8788`.

## Déploiement production

Depuis la racine du projet :

```bash
flutter build web --release --dart-define=WOW100_API_BASE_URL=/api
```

Puis depuis ce dossier `cloudflare/` :

```bash
npx wrangler pages deploy ../build/web --project-name wow100
```

## Dev Flutter avec l'API Cloudflare déjà déployée

Si l'API est déjà en ligne, tu peux garder le hot reload Flutter :

```bash
flutter run -d chrome --web-port 8080 --dart-define=WOW100_API_BASE_URL=https://wow100.pages.dev/api
```

Dans ce cas, ajoute aussi `http://localhost:8080/callback` dans Battle.net et dans `BATTLENET_ALLOWED_REDIRECT_URIS`.

## Attention avec le déploiement GitHub Cloudflare

Cloudflare Pages ne fournit pas Flutter par défaut dans son environnement de build. Pour démarrer vite, utilise plutôt le déploiement manuel direct :

```bash
flutter build web --release --dart-define=WOW100_API_BASE_URL=/api
cd cloudflare
npx wrangler pages deploy ../build/web --project-name wow100
```

On pourra ensuite ajouter une GitHub Action qui installe Flutter et déploie automatiquement vers Cloudflare Pages.
