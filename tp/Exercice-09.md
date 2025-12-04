# Exercice 9 : Ajouter la Publication Docker Hub

[⬅️ Exercice précédent](Exercice-08.md) | [🏠 Sommaire](README.md) | [Exercice suivant ➡️](Exercice-10.md)

---

## 🎯 Objectif

Publier l'image Docker sur Docker Hub avec génération de SBOM (Software Bill of Materials).

## ⏱️ Durée Estimée

30 minutes

---

## 📝 Instructions

### Étape 9.1 : Configurer les Secrets Docker Hub

1. Allez sur https://hub.docker.com/settings/security
2. Cliquez sur **New Access Token**
3. Nom : `GitHub Actions CI/CD`
4. Copiez le token

Dans GitHub : **Settings → Secrets → Actions**, ajoutez :
- `DOCKERHUB_USERNAME` : votre nom d'utilisateur Docker Hub
- `DOCKERHUB_TOKEN` : le token que vous venez de créer

### Étape 9.2 : Créer le workflow

Créez `.github/workflows/publish-docker-hub.yml` :

```yaml
name: Publish to Docker Hub

on:
  workflow_call:

env:
  DOCKER_IMAGE_NAME: demo-boost-startup-java
  DEPLOY_APPLI_NAME: demo-boost-startup-java

jobs:
  publish-docker-hub:
    name: Publish to Docker Hub
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'  # ⚠️ Seulement sur main

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

      - name: 🔐 Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: 🏷️ Tag Docker image
        run: |
          docker tag ${{ env.DOCKER_IMAGE_NAME }}:latest \
            ${{ secrets.DOCKERHUB_USERNAME }}/${{ env.DEPLOY_APPLI_NAME }}:latest
          docker tag ${{ env.DOCKER_IMAGE_NAME }}:latest \
            ${{ secrets.DOCKERHUB_USERNAME }}/${{ env.DEPLOY_APPLI_NAME }}:${{ github.sha }}

      - name: 📤 Push to Docker Hub
        run: |
          docker push ${{ secrets.DOCKERHUB_USERNAME }}/${{ env.DEPLOY_APPLI_NAME }}:latest
          docker push ${{ secrets.DOCKERHUB_USERNAME }}/${{ env.DEPLOY_APPLI_NAME }}:${{ github.sha }}

      - name: 📋 Generate SBOM
        uses: anchore/sbom-action@v0
        with:
          image: ${{ secrets.DOCKERHUB_USERNAME }}/${{ env.DEPLOY_APPLI_NAME }}:latest
          format: spdx-json
          output-file: sbom.spdx.json

      - name: 📤 Upload SBOM
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: sbom.spdx.json
          retention-days: 90
```

### Étape 9.3 : Ajouter au pipeline principal

Modifiez `main-pipeline.yml` :

```yaml
  dast-dynamic-security-testing:
    needs: build-and-scan-docker
    if: github.event_name != 'pull_request'
    uses: ./.github/workflows/dast-dynamic-security-testing.yml

  # ═══════════════════════════════════════════════
  # ÉTAPE 8 : PUBLICATION (main uniquement)
  # ═══════════════════════════════════════════════
  publish-docker-hub:
    needs:
      - build-and-scan-docker
      - dast-dynamic-security-testing
    if: github.ref == 'refs/heads/main'
    uses: ./.github/workflows/publish-docker-hub.yml
    secrets: inherit  # ⚠️ Important : partage les secrets
```

### Étape 9.4 : Tester

```bash
git add .
git commit -m "feat: add Docker Hub publication with SBOM"
git push origin main
```

Vérifiez sur Docker Hub que l'image est bien publiée !

---

## ✅ Critères de Validation

- [ ] L'image est publiée sur Docker Hub
- [ ] Deux tags sont créés : `latest` et le SHA du commit
- [ ] Le SBOM est généré au format SPDX-JSON
- [ ] Le SBOM est uploadé comme artefact (90 jours)
- [ ] **Ne s'exécute que** sur la branche `main`
- [ ] Les secrets sont partagés avec `secrets: inherit`
- [ ] L'image est visible sur https://hub.docker.com/r/USERNAME/demo-boost-startup-java

---

## 🤔 Questions de Compréhension

1. **Pourquoi utiliser un token au lieu d'un mot de passe ?**
   <details>
   <summary>Voir la réponse</summary>

   **Avantages des tokens :**
   - Plus sécurisés que les mots de passe
   - Peuvent être révoqués indépendamment
   - Ont des permissions limitées (scope)
   - Pas d'impact si compromis (juste révoquer)
   - Bonnes pratiques pour l'automatisation

   **Mot de passe :**
   - Accès complet au compte
   - Difficile à révoquer sans changer partout
   - Risque de compromission du compte entier
   </details>

2. **Qu'est-ce qu'un SBOM et pourquoi est-il important ?**
   <details>
   <summary>Voir la réponse</summary>

   **SBOM = Software Bill of Materials**

   C'est une liste exhaustive de tous les composants de votre application :
   - Bibliothèques Java (Spring Boot, etc.)
   - Version exacte de chaque dépendance
   - Packages OS (Alpine Linux)
   - Licences logicielles

   **Pourquoi c'est important :**
   - **Conformité** : Exigé par certaines régulations (USA Executive Order)
   - **Sécurité** : Savoir exactement ce qui est déployé
   - **Vulnérabilités** : Identifier rapidement si une CVE vous affecte
   - **Audit** : Traçabilité complète
   - **Licences** : Vérifier la conformité des licences

   Exemple : Log4Shell (2021) → avec un SBOM, vous savez immédiatement si vous êtes affecté.
   </details>

3. **Pourquoi `if: github.ref == 'refs/heads/main'` ?**
   <details>
   <summary>Voir la réponse</summary>

   - On ne veut publier que les versions validées (main)
   - Évite de polluer Docker Hub avec des images de test
   - Les branches de feature ne doivent pas être publiées
   - Économise de l'espace et des ressources

   **Alternative :** Publier sur une registry privée pour les branches de feature.
   </details>

4. **Pourquoi deux tags : `latest` et `<sha>` ?**
   <details>
   <summary>Voir la réponse</summary>

   **Tag `latest` :**
   - Toujours la dernière version
   - Facile à déployer : `docker pull user/app:latest`
   - Bon pour dev/staging

   **Tag `<sha>` (commit SHA) :**
   - Version immuable et traçable
   - Permet le rollback exact
   - Bon pour production
   - Lien direct avec le commit Git

   **Best practice :** Déployer avec le SHA, utiliser `latest` pour le dev.
   </details>

---

## 🎯 Architecture Actuelle

```
[...] → build-and-scan-docker
            └── dast-dynamic-security-testing
                    └── publish-docker-hub (main only)
```

Publication conditionnelle : seulement sur `main` après tous les tests de sécurité.

---

## 💡 Points Importants

### Partage de Secrets

```yaml
uses: ./.github/workflows/publish-docker-hub.yml
secrets: inherit  # ⚠️ OBLIGATOIRE
```

Sans `secrets: inherit`, le workflow réutilisable n'a **pas accès** aux secrets du repository !

### Gestion des Tags

Stratégies de tagging Docker :

```yaml
# 1. Latest (pour dev)
username/app:latest

# 2. Commit SHA (pour production)
username/app:abc123def

# 3. Version sémantique (pour releases)
username/app:v1.2.3

# 4. Branch + SHA (pour feature branches)
username/app:feature-xyz-abc123
```

---

## 📚 Ressources

- [Docker Hub](https://hub.docker.com/)
- [Docker Login Action](https://github.com/docker/login-action)
- [SBOM - SPDX Format](https://spdx.dev/)
- [Anchore SBOM Action](https://github.com/anchore/sbom-action)
- [Executive Order on Cybersecurity](https://www.nist.gov/itl/executive-order-14028-improving-nations-cybersecurity)

---

## 🎉 Félicitations !

Votre image Docker est maintenant publiée et traçable avec un SBOM ! Dans l'exercice suivant, vous allez déployer l'application en production.

[Exercice suivant : Déploiement Production ➡️](Exercice-10.md)
