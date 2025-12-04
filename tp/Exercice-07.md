# Exercice 7 : Ajouter le Build et Scan Docker

[⬅️ Exercice précédent](Exercice-06.md) | [🏠 Sommaire](README.md) | [Exercice suivant ➡️](Exercice-08.md)

---

## 🎯 Objectif

Construire l'image Docker et la scanner avec Trivy pour détecter les vulnérabilités dans l'image finale.

## ⏱️ Durée Estimée

45 minutes

---

## 📝 Instructions

### Étape 7.1 : Créer le workflow Docker

Créez `.github/workflows/build-docker-image.yml` :

```yaml
name: Build & Scan Docker Image

on:
  workflow_call:

permissions:
  security-events: write
  contents: read
  actions: read

env:
  DOCKER_IMAGE_NAME: demo-boost-startup-java

jobs:
  build-docker-image:
    name: Build Docker Image
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🐳 Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: 🏷️ Generate Docker metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.DOCKER_IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}

      - name: 🔨 Build Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: false
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          load: true

      - name: 💾 Save Docker image
        run: |
          docker save ${{ env.DOCKER_IMAGE_NAME }}:latest -o /tmp/docker-image.tar

      - name: 📤 Upload Docker image artifact
        uses: actions/upload-artifact@v4
        with:
          name: docker-image
          path: /tmp/docker-image.tar
          retention-days: 1

  # ═══════════════════════════════════════════════
  # TRIVY SCAN (dans le même workflow)
  # ═══════════════════════════════════════════════
  scan-docker-image:
    name: Scan Docker Image with Trivy
    runs-on: ubuntu-latest
    needs: build-docker-image

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 📥 Download Docker image
        uses: actions/download-artifact@v4
        with:
          name: docker-image
          path: /tmp

      - name: 🐳 Load Docker image
        run: docker load -i /tmp/docker-image.tar

      - name: 🛡️ Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.DOCKER_IMAGE_NAME }}:latest
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'  # ⚠️ Bloque le pipeline si vulnérabilités

      - name: 📤 Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v4
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
          category: trivy
```

### Étape 7.2 : Ajouter au pipeline principal

**Important** : Ce workflow doit attendre que **TOUS** les scans de sécurité soient terminés !

Modifiez `main-pipeline.yml` :

```yaml
  secure-iac-dockerfile-scan:
    needs: build-and-test
    uses: ./.github/workflows/secure-iac-dockerfile-scan.yml

  # ═══════════════════════════════════════════════
  # ÉTAPE 6 : BUILD & SCAN DOCKER
  # ═══════════════════════════════════════════════
  build-and-scan-docker:
    needs:  # ⚠️ Attend TOUS les scans de sécurité
      - code-quality-sast
      - secret-scanning
      - sca-dependency-scan
      - secure-iac-dockerfile-scan
    uses: ./.github/workflows/build-docker-image.yml
```

### Étape 7.3 : Tester

```bash
git add .
git commit -m "feat: add Docker build and Trivy scanning"
git push origin main
```

---

## ✅ Critères de Validation

- [ ] L'image Docker se construit sans erreur
- [ ] Le cache GitHub Actions fonctionne (build plus rapide au 2e run)
- [ ] Trivy scanne l'image
- [ ] Les résultats apparaissent dans Security → Code scanning
- [ ] Le pipeline échoue sur vulnérabilités CRITICAL/HIGH
- [ ] L'image est disponible comme artefact (1 jour)
- [ ] Attend que tous les scans (2-5) soient terminés
- [ ] Deux jobs dans ce workflow : build puis scan

---

## 🤔 Questions de Compréhension

1. **Pourquoi deux jobs dans le même workflow ?**
   <details>
   <summary>Voir la réponse</summary>

   Séparation des responsabilités :
   - **Job 1 (build)** : Construit l'image et l'upload
   - **Job 2 (scan)** : Download l'image et la scanne

   Avantages :
   - Si le scan échoue, l'image est déjà buildée
   - Logs plus lisibles (séparés par job)
   - Peut rejouer le scan sans rebuilder
   - Le build peut être réutilisé par d'autres workflows
   </details>

2. **À quoi sert `cache-from: type=gha` ?**
   <details>
   <summary>Voir la réponse</summary>

   Cache GitHub Actions pour Docker :
   - Sauvegarde les couches Docker entre les builds
   - Accélère considérablement les builds suivants
   - `cache-to: type=gha,mode=max` → sauvegarde toutes les couches
   - `cache-from: type=gha` → utilise le cache

   **Résultat :** Premier build 10 min, builds suivants 2-3 min !
   </details>

3. **Que scanne exactement Trivy ?**
   <details>
   <summary>Voir la réponse</summary>

   Trivy scanne plusieurs couches :
   - **OS packages** : vulnérabilités dans Alpine, Debian, Ubuntu, etc.
   - **Application dependencies** : JAR, npm, pip, etc.
   - **Misconfigurations** : vérifications IaC
   - **Secrets** : détection de secrets dans l'image

   Pour notre image Java :
   - Packages Alpine Linux
   - Le JAR de l'application
   - Les dépendances embarquées dans le JAR
   </details>

4. **Pourquoi `exit-code: '1'` est important ?**
   <details>
   <summary>Voir la réponse</summary>

   - Si Trivy trouve des vulnérabilités CRITICAL/HIGH, il retourne exit code 1
   - Cela fait échouer le job
   - Bloque le pipeline avant le déploiement
   - Force à corriger les vulnérabilités avant de continuer

   **Sans** `exit-code: 1` → les vulnérabilités sont signalées mais le pipeline continue (dangereux !)
   </details>

---

## 🎯 Architecture Actuelle

```
build-and-test
    ├── code-quality-sast ────────┐
    ├── secret-scanning ──────────┤
    ├── sca-dependency-scan ──────┼──→ build-and-scan-docker
    └── secure-iac-dockerfile-scan┘          ├── build-docker-image
                                              └── scan-docker-image
```

**Point de synchronisation !** Le build Docker attend que tous les scans de sécurité soient terminés.

---

## 💡 Points Importants

### Dépendances Multiples

```yaml
build-and-scan-docker:
  needs:  # Attend que TOUS soient terminés
    - code-quality-sast
    - secret-scanning
    - sca-dependency-scan
    - secure-iac-dockerfile-scan
```

Le job ne démarre que quand les 4 scans sont OK !

### Artefacts GitHub Actions

Les artefacts permettent de passer des données entre jobs :

```yaml
# Job 1 : Upload
- uses: actions/upload-artifact@v4
  with:
    name: docker-image
    path: /tmp/docker-image.tar

# Job 2 : Download
- uses: actions/download-artifact@v4
  with:
    name: docker-image
```

**Important** : `retention-days: 1` car les images Docker sont volumineuses !

---

## 📚 Ressources

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)
- [GitHub Actions Artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
- [Docker Cache](https://docs.docker.com/build/cache/)

---

## 🎉 Félicitations !

Votre image Docker est maintenant construite et scannée pour les vulnérabilités ! Dans l'exercice suivant, vous allez ajouter les tests DAST.

[Exercice suivant : Tests DAST ➡️](Exercice-08.md)
