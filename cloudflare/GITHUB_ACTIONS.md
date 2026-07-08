# GitHub Actions Cloudflare Pages

The workflow at `.github/workflows/deploy-cloudflare-pages.yml` builds the Flutter web app, then deploys `build/web` to the Cloudflare Pages project `wow100`.

Add these repository secrets in GitHub:

```text
CLOUDFLARE_API_TOKEN
CLOUDFLARE_ACCOUNT_ID
```

The Cloudflare API token must be allowed to deploy the Pages project `wow100`.

The workflow runs on each push to `main`, and can also be started manually from the GitHub Actions tab.

If Cloudflare Pages is still connected to the repository with its native GitHub build, disable those automatic deployments in Cloudflare after enabling this workflow. Otherwise Cloudflare will keep starting the old pipeline that does not install Flutter.
