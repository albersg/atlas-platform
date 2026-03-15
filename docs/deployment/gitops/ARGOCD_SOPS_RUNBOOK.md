# Runbook GitOps con Argo CD, KSOPS y SOPS

## Arquitectura

- `platform/argocd/core/`: instalación de Argo CD y plugin KSOPS.
- `platform/argocd/apps/`: bundle GitOps operativo para `staging`.
- `platform/k8s/overlays/*/secrets/*.enc.yaml`: secrets cifrados con SOPS.
- `.sops.yaml`: política de cifrado del repositorio.
- `.gitops-local/`: material local ignorado por git para bootstrap y validación.

## Modelo de entornos

- `dev`: entorno local-lab gestionado por `kubectl apply`, fuera de Argo CD.
- `staging`: entorno preproductivo canónico, auto-sync, prune, self-heal e imágenes desde registry por digest.
- `staging-local`: wrapper local para validar el flujo GitOps con imágenes `:main` sin debilitar `staging`.

El alcance operativo actual termina en `staging`.

## Flujo de bootstrap no production

### 1. Instalar herramientas auxiliares

```bash
mise run gitops-install-tools
```

### 2. Generar la clave age local

```bash
./scripts/gitops/bootstrap/generate-age-key.sh
```

### 3. Instalar Argo CD core

```bash
mise run gitops-bootstrap-core
```

### 4. Generar la deploy key de GitHub para Argo CD

```bash
./scripts/gitops/bootstrap/generate-repo-deploy-key.sh
```

### 5. Instalar la credential del repositorio en Argo CD

```bash
./scripts/gitops/bootstrap/install-repo-credential.sh
```

Por defecto instala la credential para `git@github.com:albersg/atlas-platform.git`
como el secret `argocd-repo-atlas-platform`. Solo sobreescribe
`GITOPS_REPO_URL` o `ARGOCD_REPO_SECRET_NAME` si necesitas apuntar a otro repo.

### 6. Instalar la clave privada age en Argo CD

```bash
mise run gitops-install-age-key
```

### 7. Aplicar las aplicaciones no productivas

```bash
mise run gitops-apply-apps
```

Esto aplica:

- `atlas-platform-staging`

Para probar una rama ya empujada antes del merge:

```bash
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-apply-apps
```

Para esperar sincronización y verificar `staging` de extremo a extremo:

```bash
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
```

En un cluster k3s local, ese commando construye e importa por defecto imágenes locales con las
refs `ghcr.io/...:main` y parchea temporalmente la Application para usar
`platform/k8s/overlays/staging-local`. Ese wrapper conserva el render KSOPS y el flujo Argo CD,
pero evita depender de que GHCR tenga publicadas las tags `:main` durante la validación local.
El overlay canónico `platform/k8s/overlays/staging` queda reservado al camino registry-first
con digests inmutables.

Para probar el overlay canónico `platform/k8s/overlays/staging` contra imágenes realmente
publicadas en registry:

```bash
STAGING_LOCAL_IMAGES=0 ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
```

## Validación local antes de sincronizar

```bash
mise run gitops-render-dev >/dev/null
mise run gitops-render-staging >/dev/null
mise run k8s-validate-overlays
```

`mise run k8s-validate-overlays` aplica políticas comunes a `dev`, `staging` y `staging-local`,
pero ejecuta las reglas de inmutabilidad solo sobre `staging` canónico. Además valida que las
imágenes digest-pinned de `staging` tengan firma Cosign verificable desde el workflow
`Release Images` de GitHub Actions en `main`.

## Acceso local a Argo CD

```bash
./scripts/gitops/argocd/login-local.sh
```

```bash
./scripts/gitops/argocd/get-initial-password.sh
```

## Política de sync

- `atlas-platform-staging`: auto-sync, prune y self-heal.

Antes de destruir `staging`, usa el teardown GitOps-aware:

```bash
ATLAS_CONFIRM_STAGING_DELETE=atlas-platform-staging mise run k8s-delete-staging
```

Ese flujo elimina primero la `Application` sin cascada para evitar que `self-heal`
recree recursos mientras se limpian los workloads. El `Namespace` y los PVC se
preservan por defecto salvo `PRESERVE_POSTGRES_PVC=0`.

## Promoción de imágenes

La promoción correcta ya no es por tags mutables sino por digest.

`staging` debe consumir imágenes publicadas en registry. El workflow de promoción exige `SOPS_AGE_KEY`
para validar el overlay antes de abrir la PR y ahora rechaza digests sin firma verificable.

Si solo quieres un preflight local de render/política sin exigir el camino GitOps endurecido,
usa `ATLAS_DOCTOR_SCOPE=dev mise run k8s-doctor`.

Consulta:

- `docs/deployment/releases/IMAGE_PROMOTION.md`

## Rotación de claves SOPS

Si rotas la pareja de claves age:

1. actualiza `.sops.yaml`,
2. re-cifra `platform/k8s/overlays/*/secrets/*.enc.yaml`,
3. actualiza `argocd-sops-age-key` en el cluster correspondiente,
4. vuelve a renderizar overlays localmente,
5. re-sincroniza Argo CD.

## Notas de seguridad

- no commits `.gitops-local/age/keys.txt`,
- no commits `.gitops-local/ssh/argocd-repo`,
- trata el namespace `argocd` como sensible,
- mantén `dev` y `staging` como frontera no productiva,
- configura `SOPS_AGE_KEY` en GitHub Actions para validar overlays cifrados en CI y promoción,
- deja producción fuera de este flujo hasta tener infraestructura separada.
