# TP : Créer un Pipeline CI/CD GitHub Actions Modulaire - Étape par Étape

## 🎯 Objectifs Pédagogiques

À la fin de ce TP, vous serez capable de :
- Créer un pipeline CI/CD modulaire avec des workflows réutilisables
- Comprendre l'architecture `workflow_call` de GitHub Actions
- Intégrer des outils de sécurité (SAST, SCA, DAST) progressivement
- Construire et déployer une application Java avec Docker
- Orchestrer plusieurs workflows avec un pipeline principal

## 📋 Prérequis

- Compte GitHub
- Projet Java/Spring Boot avec Maven
- Compte Docker Hub
- Serveur de déploiement (Ubuntu/Debian)
- Connaissance de base : Git, Docker, Java

## ⏱️ Durée Estimée

- **Durée totale :** 5-7 heures
- **Niveau :** Intermédiaire à Avancé

---

## 🏗️ Architecture du Pipeline

Nous allons créer une architecture **modulaire** avec :
- **1 workflow principal** (`main-pipeline.yml`) que nous allons enrichir progressivement
- **9 workflows réutilisables** que nous ajouterons un par un

```
main-pipeline.yml (orchestrateur)
    ├── build-unit-tests.yml           [Exercice 2]
    ├── code-quality-sast.yml          [Exercice 3]
    ├── secret-scanning.yml            [Exercice 4]
    ├── sca-dependency-scan.yml        [Exercice 5]
    ├── secure-iac-dockerfile-scan.yml [Exercice 6]
    ├── build-docker-image.yml         [Exercice 7]
    ├── dast-dynamic-security-testing.yml [Exercice 8]
    ├── publish-docker-hub.yml         [Exercice 9]
    └── deploy-production-server.yml   [Exercice 10]
```

### ✨ Avantages de cette Approche

1. **Réutilisabilité** : Chaque workflow peut être utilisé indépendamment
2. **Maintenabilité** : Modification d'un seul fichier pour chaque fonctionnalité
3. **Testabilité** : Test individuel de chaque workflow
4. **Lisibilité** : Code organisé et facile à comprendre
5. **Parallélisation** : Exécution simultanée des workflows indépendants

---

## 📚 Structure du TP

Le TP est divisé en **11 exercices progressifs** :

1. 🎼 **Création du pipeline principal (squelette)**
2. ✅ Ajout du workflow de build et tests unitaires
3. 🔍 Ajout du workflow d'analyse SAST
4. 🔐 Ajout du workflow de détection de secrets
5. 📦 Ajout du workflow d'analyse des dépendances (SCA)
6. 🏗️ Ajout du workflow de sécurité IaC
7. 🐳 Ajout du workflow de build Docker
8. 🎯 Ajout du workflow de tests DAST
9. 📤 Ajout du workflow de publication Docker Hub
10. 🚀 Ajout du workflow de déploiement en production
11. 🔔 Ajout des notifications

---

## 🎼 Exercice 1 : Créer le Pipeline Principal (Squelette)

### 🎯 Objectif
Créer le workflow principal `main-pipeline.yml` qui servira d'orchestrateur. Nous allons le remplir progressivement au fur et à mesure des exercices.

### 📝 Instructions

#### Étape 1.1 : Créer la structure de base

Créez le fichier `.github/workflows/main-pipeline.yml` :

```yaml
name: Main CI/CD Pipeline

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  schedule:
    - cron: '0 2 * * 1'  # Tous les lundis à 2h du matin
  workflow_dispatch:  # Permet le déclenchement manuel

permissions:
  security-events: write
  contents: read
  actions: read

jobs:
  # ═══════════════════════════════════════════════
  # Les jobs seront ajoutés progressivement dans les exercices suivants
  # ═══════════════════════════════════════════════

  placeholder:
    name: Pipeline Principal - En Construction
    runs-on: ubuntu-latest
    steps:
      - name: 📋 Pipeline en construction
        run: |
          echo "🚧 Pipeline CI/CD en cours de construction..."
          echo "Les workflows seront ajoutés progressivement dans les exercices suivants."
          echo ""
          echo "📚 Exercices à venir:"
          echo "  ✅ Build & Tests Unitaires"
          echo "  🔍 Analyse de Code (SAST)"
          echo "  🔐 Détection de Secrets"
          echo "  📦 Analyse des Dépendances (SCA)"
          echo "  🏗️ Sécurité Infrastructure as Code"
          echo "  🐳 Build Docker & Scan"
          echo "  🎯 Tests de Sécurité Dynamiques (DAST)"
          echo "  📤 Publication Docker Hub"
          echo "  🚀 Déploiement Production"
```

#### Étape 1.2 : Comprendre la structure

**Déclencheurs (`on:`)** :
- `push: branches: [main]` : Se déclenche sur chaque push vers main
- `pull_request: branches: [main]` : Se déclenche sur les PRs vers main
- `schedule: cron` : Exécution planifiée (chaque lundi à 2h)
- `workflow_dispatch` : Permet de lancer manuellement le workflow

**Permissions** :
- `security-events: write` : Pour uploader les résultats SARIF vers GitHub Security
- `contents: read` : Pour lire le code du repository
- `actions: read` : Pour lire les workflows

#### Étape 1.3 : Commiter et tester

```bash
git add .github/workflows/main-pipeline.yml
git commit -m "feat: add main pipeline skeleton"
git push origin main
```

Allez dans **Actions** → Vous devriez voir le workflow s'exécuter !

### ✅ Critères de Validation

- [ ] Le fichier `main-pipeline.yml` est créé dans `.github/workflows/`
- [ ] Le workflow apparaît dans l'onglet "Actions" de GitHub
- [ ] Le job `placeholder` s'exécute avec succès
- [ ] Vous comprenez les 4 types de déclencheurs

### 🤔 Questions de Compréhension

1. Quelle est la différence entre `push` et `pull_request` ?
2. À quoi sert `workflow_dispatch` ?
3. Pourquoi avons-nous besoin de `security-events: write` ?
4. Que se passe-t-il si on commente `schedule:` ?

---

## ✅ Exercice 2 : Ajouter le Workflow de Build et Tests

### 🎯 Objectif
Créer le premier workflow réutilisable pour compiler et tester l'application, puis l'intégrer au pipeline principal.

### 📝 Instructions

#### Étape 2.1 : Créer le workflow réutilisable

Créez le fichier `.github/workflows/build-unit-tests.yml` :

```yaml
name: Build & Unit Tests

on:
  workflow_call:  # ⚠️ Important : permet d'être appelé par d'autres workflows

jobs:
  build-and-test:
    name: Build & Unit Tests
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: ☕ Set up JDK
        uses: actions/setup-java@v4
        with:
          java-version: '25'
          distribution: 'liberica'
          cache: 'maven'

      - name: 🔨 Build with Maven
        run: mvn clean compile -DskipTests=false

      - name: 🧪 Run unit tests
        run: mvn test

      - name: 📊 Generate test coverage report
        run: mvn jacoco:report || true

      - name: 📦 Package application
        run: mvn package -DskipTests=true

      - name: 📤 Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: build-artifacts
          path: target/*.jar
          retention-days: 7
```

#### Étape 2.2 : Intégrer au pipeline principal

Modifiez `.github/workflows/main-pipeline.yml` :

**SUPPRIMEZ** le job `placeholder` et **AJOUTEZ** :

```yaml
jobs:
  # ═══════════════════════════════════════════════
  # ÉTAPE 1 : BUILD & TESTS
  # ═══════════════════════════════════════════════
  build-and-test:
    uses: ./.github/workflows/build-unit-tests.yml
```

Votre `main-pipeline.yml` devrait maintenant ressembler à :

```yaml
name: Main CI/CD Pipeline

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  schedule:
    - cron: '0 2 * * 1'
  workflow_dispatch:

permissions:
  security-events: write
  contents: read
  actions: read

jobs:
  # ═══════════════════════════════════════════════
  # ÉTAPE 1 : BUILD & TESTS
  # ═══════════════════════════════════════════════
  build-and-test:
    uses: ./.github/workflows/build-unit-tests.yml
```

#### Étape 2.3 : Tester

```bash
git add .
git commit -m "feat: add build and unit tests workflow"
git push origin main
```

### ✅ Critères de Validation

- [ ] Le workflow `build-unit-tests.yml` existe
- [ ] Il utilise `workflow_call` comme déclencheur
- [ ] Le `main-pipeline.yml` appelle ce workflow avec `uses:`
- [ ] La compilation Maven réussit
- [ ] Les tests passent
- [ ] L'artefact JAR est uploadé

### 🤔 Questions de Compréhension

1. Quelle est la différence entre `workflow_call` et `push` ?
2. Pourquoi utiliser `uses: ./.github/workflows/...` ?
3. À quoi sert `retention-days: 7` ?
4. Que fait `cache: 'maven'` ?

---

## 🔍 Exercice 3 : Ajouter l'Analyse SAST

### 🎯 Objectif
Ajouter l'analyse de sécurité statique (SAST) avec Semgrep et CodeQL.

### 📝 Instructions

#### Étape 3.1 : Créer le workflow SAST

Créez `.github/workflows/code-quality-sast.yml` :

```yaml
name: Code Quality & SAST

on:
  workflow_call:

permissions:
  security-events: write
  contents: read
  actions: read

jobs:
  code-quality-sast:
    name: Code Quality & SAST
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      # ═══════════════════════════════════════
      # SEMGREP SAST
      # ═══════════════════════════════════════
      - name: 🔍 Run Semgrep SAST
        uses: returntocorp/semgrep-action@v1
        with:
          config: 'auto'
        env:
          SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
        continue-on-error: true

      - name: 📤 Upload Semgrep SARIF
        uses: github/codeql-action/upload-sarif@v4
        if: always() && hashFiles('semgrep.sarif') != ''
        with:
          sarif_file: semgrep.sarif
          category: semgrep

      # ═══════════════════════════════════════
      # CODEQL SAST
      # ═══════════════════════════════════════
      - name: 🔍 Initialize CodeQL
        uses: github/codeql-action/init@v4
        with:
          languages: 'java-kotlin'
          queries: security-extended,security-and-quality

      - name: ☕ Setup JDK for CodeQL
        uses: actions/setup-java@v4
        with:
          java-version: '25'
          distribution: 'liberica'
          cache: 'maven'

      - name: 🔨 Build for CodeQL
        run: mvn clean compile -DskipTests=true

      - name: 🔍 Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v4
        with:
          category: codeql-java
```

#### Étape 3.2 : Ajouter au pipeline principal

Modifiez `.github/workflows/main-pipeline.yml` en ajoutant :

```yaml
jobs:
  build-and-test:
    uses: ./.github/workflows/build-unit-tests.yml

  # ═══════════════════════════════════════════════
  # ÉTAPE 2 : ANALYSE DE SÉCURITÉ STATIQUE (SAST)
  # ═══════════════════════════════════════════════
  code-quality-sast:
    needs: build-and-test  # ⚠️ Attend que le build soit terminé
    uses: ./.github/workflows/code-quality-sast.yml
```

### ✅ Critères de Validation

- [ ] Semgrep s'exécute et génère un SARIF
- [ ] CodeQL analyse le code Java
- [ ] Les résultats apparaissent dans **Security → Code scanning**
- [ ] Le job attend que `build-and-test` soit terminé (`needs:`)

### 🤔 Questions de Compréhension

1. Pourquoi `needs: build-and-test` ?
2. Quelle est la différence entre Semgrep et CodeQL ?
3. Qu'est-ce qu'un fichier SARIF ?
4. Pourquoi `continue-on-error: true` pour Semgrep ?

---

## 🔐 Exercice 4 : Ajouter la Détection de Secrets

### 🎯 Objectif
Détecter les secrets (clés API, tokens) dans le code source avec Gitleaks.

### 📝 Instructions

#### Étape 4.1 : Créer le workflow

Créez `.github/workflows/secret-scanning.yml` :

```yaml
name: Secret Scanning

on:
  workflow_call:

jobs:
  secret-scanning:
    name: Secret Scanning with Gitleaks
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # ⚠️ Important : scanne tout l'historique

      - name: 🔐 Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}
```

#### Étape 4.2 : Ajouter au pipeline principal

Modifiez `main-pipeline.yml` :

```yaml
  code-quality-sast:
    needs: build-and-test
    uses: ./.github/workflows/code-quality-sast.yml

  # ═══════════════════════════════════════════════
  # ÉTAPE 3 : DÉTECTION DE SECRETS
  # ═══════════════════════════════════════════════
  secret-scanning:
    needs: build-and-test  # S'exécute en PARALLÈLE avec code-quality-sast
    uses: ./.github/workflows/secret-scanning.yml
```

### 🎯 Exécution en Parallèle

**Important** : `code-quality-sast` et `secret-scanning` ont tous les deux `needs: build-and-test`, donc ils s'exécutent **en parallèle** après le build !

```
build-and-test
    ├── code-quality-sast    (parallèle)
    └── secret-scanning      (parallèle)
```

### ✅ Critères de Validation

- [ ] Gitleaks scanne tout l'historique Git
- [ ] Le workflow s'exécute en parallèle avec SAST
- [ ] Les secrets sont détectés si présents

### 🤔 Questions de Compréhension

1. Pourquoi `fetch-depth: 0` ?
2. Comment deux jobs peuvent s'exécuter en parallèle ?
3. Que détecte Gitleaks ?

---

## 📦 Exercice 5 : Ajouter l'Analyse des Dépendances (SCA)

### 🎯 Objectif
Identifier les vulnérabilités dans les dépendances Maven avec OWASP Dependency-Check.

### 📝 Instructions

#### Étape 5.1 : Créer le fichier de suppressions

Créez `.github/dependency-check-suppressions.xml` :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
    <!-- Exemple : Supprimer un faux positif -->
    <!--
    <suppress>
        <notes>False positive for Spring Boot Actuator</notes>
        <packageUrl regex="true">^pkg:maven/org\.springframework\.boot/spring\-boot\-actuator.*$</packageUrl>
        <cve>CVE-2023-XXXXX</cve>
    </suppress>
    -->
</suppressions>
```

#### Étape 5.2 : Créer le workflow SCA

Créez `.github/workflows/sca-dependency-scan.yml` :

```yaml
name: SCA - Dependency Scan

on:
  workflow_call:

permissions:
  security-events: write
  contents: read

jobs:
  sca-dependency-scan:
    name: SCA - OWASP Dependency Check
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: ☕ Set up JDK
        uses: actions/setup-java@v4
        with:
          java-version: '25'
          distribution: 'liberica'
          cache: 'maven'

      - name: 📦 Run OWASP Dependency Check
        run: |
          mvn org.owasp:dependency-check-maven:11.1.1:check \
            -DfailBuildOnCVSS=7 \
            -DsuppressionFile=.github/dependency-check-suppressions.xml \
            -Dformats=HTML,SARIF

      - name: 📤 Upload Dependency Check SARIF
        uses: github/codeql-action/upload-sarif@v4
        if: always() && hashFiles('target/dependency-check-report.sarif') != ''
        with:
          sarif_file: target/dependency-check-report.sarif
          category: dependency-check

      - name: 📤 Upload Dependency Check Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: dependency-check-report
          path: target/dependency-check-report.html
          retention-days: 30
```

#### Étape 5.3 : Ajouter au pipeline principal

```yaml
  secret-scanning:
    needs: build-and-test
    uses: ./.github/workflows/secret-scanning.yml

  # ═══════════════════════════════════════════════
  # ÉTAPE 4 : ANALYSE DES DÉPENDANCES (SCA)
  # ═══════════════════════════════════════════════
  sca-dependency-scan:
    needs: build-and-test  # Également en parallèle
    uses: ./.github/workflows/sca-dependency-scan.yml
```

### 🎯 État actuel de la parallélisation

```
build-and-test
    ├── code-quality-sast      (parallèle)
    ├── secret-scanning        (parallèle)
    └── sca-dependency-scan    (parallèle)
```

### ✅ Critères de Validation

- [ ] Le scan des dépendances s'exécute
- [ ] Le rapport HTML et SARIF sont générés
- [ ] Le build échoue si CVSS >= 7
- [ ] S'exécute en parallèle avec SAST et Secret Scanning

### 🤔 Questions de Compréhension

1. Qu'est-ce qu'un score CVSS ?
2. Pourquoi un seuil de 7 ?
3. Comment mettre à jour une dépendance vulnérable ?

---

## 🏗️ Exercice 6 : Ajouter la Sécurité IaC (Dockerfile)

### 🎯 Objectif
Analyser le Dockerfile pour détecter les mauvaises configurations de sécurité avec Checkov.

### 📝 Instructions

#### Étape 6.1 : Créer le workflow IaC

Créez `.github/workflows/secure-iac-dockerfile-scan.yml` :

```yaml
name: Secure IaC - Dockerfile Scan

on:
  workflow_call:

permissions:
  security-events: write
  contents: read

jobs:
  secure-iac-dockerfile-scan:
    name: IaC Security - Checkov
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🏗️ Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          framework: dockerfile
          output_format: sarif
          soft_fail: false
          output_file_path: checkov-report.sarif

      - name: 📤 Upload Checkov SARIF
        uses: github/codeql-action/upload-sarif@v4
        if: always() && hashFiles('checkov-report.sarif') != ''
        with:
          sarif_file: checkov-report.sarif
          category: checkov
```

#### Étape 6.2 : Ajouter au pipeline principal

```yaml
  sca-dependency-scan:
    needs: build-and-test
    uses: ./.github/workflows/sca-dependency-scan.yml

  # ═══════════════════════════════════════════════
  # ÉTAPE 5 : SÉCURITÉ INFRASTRUCTURE AS CODE
  # ═══════════════════════════════════════════════
  secure-iac-dockerfile-scan:
    needs: build-and-test  # Toujours en parallèle
    uses: ./.github/workflows/secure-iac-dockerfile-scan.yml
```

### 🎯 Parallélisation actuelle

```
build-and-test
    ├── code-quality-sast
    ├── secret-scanning
    ├── sca-dependency-scan
    └── secure-iac-dockerfile-scan
```

**Les 4 scans de sécurité s'exécutent en parallèle !** ⚡

### ✅ Critères de Validation

- [ ] Checkov analyse le Dockerfile
- [ ] Les violations de sécurité sont détectées
- [ ] S'exécute en parallèle avec les autres scans

---

## 🐳 Exercice 7 : Ajouter le Build et Scan Docker

### 🎯 Objectif
Construire l'image Docker et la scanner avec Trivy.

### 📝 Instructions

#### Étape 7.1 : Créer le workflow Docker

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

#### Étape 7.2 : Ajouter au pipeline principal

**Important** : Ce workflow doit attendre que TOUS les scans de sécurité soient terminés !

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

### 🎯 Architecture actuelle

```
build-and-test
    ├── code-quality-sast ────────┐
    ├── secret-scanning ──────────┤
    ├── sca-dependency-scan ──────┼──→ build-and-scan-docker
    └── secure-iac-dockerfile-scan┘
```

### ✅ Critères de Validation

- [ ] L'image Docker se construit
- [ ] Trivy scanne l'image
- [ ] Le pipeline échoue sur vulnérabilités CRITICAL/HIGH
- [ ] L'image est disponible comme artefact
- [ ] Attend que tous les scans soient terminés

---

## 🎯 Exercice 8 : Ajouter les Tests DAST

### 🎯 Objectif
Tester l'application en cours d'exécution avec OWASP ZAP.

### 📝 Instructions

#### Étape 8.1 : Créer la configuration ZAP

Créez `.zap/rules.tsv` :

```tsv
10003	IGNORE	(Vulnerable JS Library)
10015	IGNORE	(Re-examine Cache-control Directives)
10027	IGNORE	(Information Disclosure - Suspicious Comments)
10096	IGNORE	(Timestamp Disclosure)
10109	IGNORE	(Modern Web Application)
```

#### Étape 8.2 : Créer le workflow DAST

Créez `.github/workflows/dast-dynamic-security-testing.yml` :

```yaml
name: DAST - Dynamic Security Testing

on:
  workflow_call:

env:
  DOCKER_IMAGE_NAME: demo-boost-startup-java

jobs:
  dast-dynamic-security-testing:
    name: DAST - OWASP ZAP
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 📥 Download Docker image
        uses: actions/download-artifact@v4
        with:
          name: docker-image
          path: /tmp

      - name: 🐳 Load and start application
        run: |
          docker load -i /tmp/docker-image.tar
          docker run -d --name test-app -p 8080:8080 ${{ env.DOCKER_IMAGE_NAME }}:latest

          echo "⏳ Waiting for application to start..."
          for i in {1..30}; do
            if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
              echo "✅ Application is ready!"
              break
            fi
            echo "Attempt $i/30..."
            sleep 2
          done

      - name: 🎯 Run OWASP ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.12.0
        with:
          target: 'http://localhost:8080'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'

      - name: 📤 Upload ZAP Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: zap-report
          path: report_html.html
          retention-days: 30

      - name: 🧹 Cleanup
        if: always()
        run: |
          docker stop test-app || true
          docker rm test-app || true
```

#### Étape 8.3 : Ajouter au pipeline principal

**Important** : DAST ne s'exécute PAS sur les Pull Requests (trop long).

```yaml
  build-and-scan-docker:
    needs:
      - code-quality-sast
      - secret-scanning
      - sca-dependency-scan
      - secure-iac-dockerfile-scan
    uses: ./.github/workflows/build-docker-image.yml

  # ═══════════════════════════════════════════════
  # ÉTAPE 7 : DAST (Pas sur les PRs)
  # ═══════════════════════════════════════════════
  dast-dynamic-security-testing:
    needs: build-and-scan-docker
    if: github.event_name != 'pull_request'  # ⚠️ Désactivé sur les PRs
    uses: ./.github/workflows/dast-dynamic-security-testing.yml
```

### ✅ Critères de Validation

- [ ] L'application démarre dans Docker
- [ ] ZAP scanne l'application
- [ ] Le rapport est généré
- [ ] Ne s'exécute PAS sur les PRs

### 🤔 Questions

1. Pourquoi désactiver DAST sur les PRs ?
2. Différence entre SAST et DAST ?

---

## 📤 Exercice 9 : Ajouter la Publication Docker Hub

### 🎯 Objectif
Publier l'image Docker sur Docker Hub avec génération de SBOM.

### 📝 Instructions

#### Étape 9.1 : Configurer les Secrets

Dans GitHub : **Settings → Secrets → Actions**
- `DOCKERHUB_USERNAME` : votre username Docker Hub
- `DOCKERHUB_TOKEN` : token de https://hub.docker.com/settings/security

#### Étape 9.2 : Créer le workflow

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

#### Étape 9.3 : Ajouter au pipeline principal

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

### ✅ Critères de Validation

- [ ] L'image est publiée sur Docker Hub
- [ ] Les tags `latest` et `sha` sont créés
- [ ] Le SBOM est généré
- [ ] Seulement sur la branche `main`
- [ ] Les secrets sont partagés avec `secrets: inherit`

---

## 🚀 Exercice 10 : Ajouter le Déploiement en Production

### 🎯 Objectif
Déployer automatiquement l'application sur un serveur via SSH.

### 📝 Instructions

#### Étape 10.1 : Configurer les Secrets SSH

Voir `.github/SECRETS.md` pour le guide complet.

Secrets requis :
- `DEPLOY_SERVER`
- `DEPLOY_SSH_USER`
- `DEPLOY_SSH_PRIVATE_KEY`
- `DEPLOY_SSH_PORT`
- `DEPLOY_APPLI_PORT`
- `DEPLOY_APPLI_NAME`

#### Étape 10.2 : Créer le workflow

Créez `.github/workflows/deploy-production-server.yml` :

```yaml
name: Deploy to Production Server

on:
  workflow_call:

env:
  DEPLOY_APPLI_NAME: demo-boost-startup-java

jobs:
  deploy-production-server:
    name: Deploy to Production
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🔐 Configure SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.DEPLOY_SSH_PRIVATE_KEY }}" > ~/.ssh/deploy_key
          chmod 600 ~/.ssh/deploy_key
          ssh-keyscan -p ${{ secrets.DEPLOY_SSH_PORT || 22 }} \
            ${{ secrets.DEPLOY_SERVER }} >> ~/.ssh/known_hosts

      - name: 🚀 Deploy to server
        run: |
          ssh -i ~/.ssh/deploy_key \
            -p ${{ secrets.DEPLOY_SSH_PORT || 22 }} \
            ${{ secrets.DEPLOY_SSH_USER }}@${{ secrets.DEPLOY_SERVER }} << 'ENDSSH'

            echo "📥 Pulling latest Docker image..."
            docker pull ${{ secrets.DOCKERHUB_USERNAME }}/${{ env.DEPLOY_APPLI_NAME }}:latest

            echo "🛑 Stopping old container..."
            docker stop ${{ secrets.DEPLOY_APPLI_NAME }} 2>/dev/null || true
            docker rm ${{ secrets.DEPLOY_APPLI_NAME }} 2>/dev/null || true

            echo "🚀 Starting new container..."
            docker run -d \
              --name ${{ secrets.DEPLOY_APPLI_NAME }} \
              --restart unless-stopped \
              -p ${{ secrets.DEPLOY_APPLI_PORT }}:8080 \
              -e SPRING_PROFILES_ACTIVE=production \
              ${{ secrets.DOCKERHUB_USERNAME }}/${{ env.DEPLOY_APPLI_NAME }}:latest

            echo "⏳ Waiting for application health check..."
            for i in {1..30}; do
              if curl -f http://localhost:${{ secrets.DEPLOY_APPLI_PORT }}/actuator/health > /dev/null 2>&1; then
                echo "✅ Application is healthy!"
                exit 0
              fi
              echo "Attempt $i/30..."
              sleep 2
            done

            echo "❌ Health check failed!"
            exit 1
          ENDSSH

      - name: 🧹 Cleanup old images
        run: |
          ssh -i ~/.ssh/deploy_key \
            -p ${{ secrets.DEPLOY_SSH_PORT || 22 }} \
            ${{ secrets.DEPLOY_SSH_USER }}@${{ secrets.DEPLOY_SERVER }} \
            "docker image prune -af --filter 'until=24h'"

      - name: 🧹 Cleanup SSH key
        if: always()
        run: rm -f ~/.ssh/deploy_key
```

#### Étape 10.3 : Ajouter au pipeline principal

```yaml
  publish-docker-hub:
    needs:
      - build-and-scan-docker
      - dast-dynamic-security-testing
    if: github.ref == 'refs/heads/main'
    uses: ./.github/workflows/publish-docker-hub.yml
    secrets: inherit

  # ═══════════════════════════════════════════════
  # ÉTAPE 9 : DÉPLOIEMENT EN PRODUCTION
  # ═══════════════════════════════════════════════
  deploy-production-server:
    needs: publish-docker-hub
    uses: ./.github/workflows/deploy-production-server.yml
    secrets: inherit  # ⚠️ Important
```

### ✅ Critères de Validation

- [ ] Le déploiement SSH fonctionne
- [ ] L'application est accessible
- [ ] Le health check réussit
- [ ] Seulement sur `main`

---

## 🔔 Exercice 11 : Ajouter les Notifications

### 🎯 Objectif
Ajouter un job de notification qui affiche le statut final du pipeline.

### 📝 Instructions

Ajoutez ce job à la fin de `main-pipeline.yml` :

```yaml
  deploy-production-server:
    needs: publish-docker-hub
    uses: ./.github/workflows/deploy-production-server.yml
    secrets: inherit

  # ═══════════════════════════════════════════════
  # NOTIFICATIONS
  # ═══════════════════════════════════════════════
  send-notifications:
    name: Send Notifications
    needs:
      - build-and-test
      - code-quality-sast
      - secret-scanning
      - sca-dependency-scan
      - secure-iac-dockerfile-scan
      - build-and-scan-docker
      - deploy-production-server
    runs-on: ubuntu-latest
    if: always()  # ⚠️ Toujours exécuter

    steps:
      - name: 📊 Check pipeline status
        run: |
          echo "═══════════════════════════════════════"
          echo "📊 PIPELINE STATUS REPORT"
          echo "═══════════════════════════════════════"
          echo "Build & Test: ${{ needs.build-and-test.result }}"
          echo "SAST: ${{ needs.code-quality-sast.result }}"
          echo "Secret Scanning: ${{ needs.secret-scanning.result }}"
          echo "SCA: ${{ needs.sca-dependency-scan.result }}"
          echo "IaC Security: ${{ needs.secure-iac-dockerfile-scan.result }}"
          echo "Docker Build: ${{ needs.build-and-scan-docker.result }}"
          echo "Deployment: ${{ needs.deploy-production-server.result }}"
          echo "═══════════════════════════════════════"

      - name: ✅ Deployment successful
        if: needs.deploy-production-server.result == 'success'
        run: |
          echo "✅ Deployment to production successful!"
          echo "🎉 Application is live!"

      - name: ❌ Deployment failed
        if: needs.deploy-production-server.result == 'failure'
        run: |
          echo "❌ Deployment to production failed!"
          echo "🚨 Please check the logs and rollback if necessary."
          exit 1

      - name: ⚠️ Pipeline skipped
        if: needs.deploy-production-server.result == 'skipped'
        run: |
          echo "⚠️ Deployment was skipped (not on main branch)"
          echo "✅ Security scans and tests completed successfully!"
```

### ✅ Critères de Validation

- [ ] Le job s'exécute toujours (`if: always()`)
- [ ] Le statut de tous les jobs est affiché
- [ ] Les notifications diffèrent selon le résultat

---

## 📊 Architecture Finale du Pipeline

Voici le flux complet du pipeline que vous avez construit :

```
main-pipeline.yml (Orchestrateur)
│
├─[1]─ build-unit-tests.yml
│       │
│       ├─[2]─ code-quality-sast.yml ────────┐
│       ├─[3]─ secret-scanning.yml ──────────┤
│       ├─[4]─ sca-dependency-scan.yml ──────┼─[6]─ build-docker-image.yml
│       └─[5]─ secure-iac-dockerfile-scan.yml─┘       │
│                                                      │
│                                             [7]─ dast-dynamic-security-testing.yml
│                                                      │
│                                             [8]─ publish-docker-hub.yml
│                                                      │
│                                             [9]─ deploy-production-server.yml
│                                                      │
└─────────────────────────────────────────────[10]─ send-notifications
```

### 🔄 Flux d'Exécution

| Étape | Jobs | Durée | Exécution |
|-------|------|-------|-----------|
| 1 | Build & Tests | 3-5 min | Toujours |
| 2-5 | SAST, Secrets, SCA, IaC | 8-12 min | **Parallèle** |
| 6 | Docker Build + Trivy | 5-8 min | Après 2-5 |
| 7 | DAST (OWASP ZAP) | 5-10 min | Pas sur PR |
| 8 | Publish Docker Hub | 2-3 min | Main uniquement |
| 9 | Deploy Production | 2-3 min | Main uniquement |
| 10 | Notifications | 10 sec | Toujours |

**Durée totale :**
- **PR** : ~20-30 min (sans DAST/Deploy)
- **Main** : ~30-45 min (pipeline complet)

---

## 📝 Checklist de Validation Finale

### Configuration
- [ ] Tous les fichiers workflow sont créés
- [ ] Tous les secrets GitHub sont configurés
- [ ] Le serveur de déploiement est prêt
- [ ] Docker Hub est configuré
- [ ] Les clés SSH fonctionnent

### Workflows Créés
- [ ] `main-pipeline.yml` (orchestrateur)
- [ ] `build-unit-tests.yml`
- [ ] `code-quality-sast.yml`
- [ ] `secret-scanning.yml`
- [ ] `sca-dependency-scan.yml`
- [ ] `secure-iac-dockerfile-scan.yml`
- [ ] `build-docker-image.yml`
- [ ] `dast-dynamic-security-testing.yml`
- [ ] `publish-docker-hub.yml`
- [ ] `deploy-production-server.yml`

### Pipeline Principal
- [ ] Les jobs s'exécutent dans le bon ordre
- [ ] Les jobs parallèles fonctionnent (2-5)
- [ ] Les conditions `if:` sont respectées
- [ ] `secrets: inherit` est utilisé
- [ ] Les dépendances `needs:` sont correctes

### Sécurité
- [ ] SAST détecte les vulnérabilités
- [ ] Les secrets sont détectés
- [ ] Les dépendances vulnérables sont trouvées
- [ ] Le Dockerfile est validé
- [ ] Trivy bloque sur CRITICAL/HIGH
- [ ] ZAP teste l'application

### Déploiement
- [ ] L'image est publiée sur Docker Hub
- [ ] Le SBOM est généré
- [ ] Le déploiement SSH fonctionne
- [ ] L'application est accessible
- [ ] Le health check réussit

---

## 🎯 Concepts Clés Maîtrisés

Après ce TP, vous maîtrisez :

### GitHub Actions
- ✅ `workflow_call` : Créer des workflows réutilisables
- ✅ `uses:` : Appeler des workflows depuis le pipeline principal
- ✅ `needs:` : Gérer les dépendances entre jobs
- ✅ `if:` : Conditions d'exécution
- ✅ `secrets: inherit` : Partager les secrets
- ✅ Exécution parallèle vs séquentielle

### DevSecOps
- ✅ SAST (Semgrep + CodeQL)
- ✅ Secret Scanning (Gitleaks)
- ✅ SCA (OWASP Dependency-Check)
- ✅ IaC Security (Checkov)
- ✅ Container Scanning (Trivy)
- ✅ DAST (OWASP ZAP)
- ✅ SBOM (Software Bill of Materials)

### Docker & Déploiement
- ✅ Build multi-stage
- ✅ Cache GitHub Actions
- ✅ Déploiement SSH
- ✅ Health checks
- ✅ Rollback strategies

---

## 🐛 Dépannage

### Problème : "workflow_call event is not available"
**Solution :** Vérifiez `on: workflow_call:` dans le workflow réutilisable

### Problème : "secret not found"
**Solution :** Ajoutez `secrets: inherit` dans le workflow principal

### Problème : "artifact not found"
**Solution :** Vérifiez que le job précédent a uploadé l'artefact

### Problème : "job skipped"
**Solution :** Vérifiez les conditions `if:` et les dépendances `needs:`

### Problème : Jobs ne s'exécutent pas en parallèle
**Solution :** Vérifiez que tous ont le même `needs:` (ex: `build-and-test`)

---

## 📚 Ressources

- [GitHub Actions - Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [GitHub Actions - Workflow syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [OWASP DevSecOps](https://owasp.org/www-project-devsecops-guideline/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

**Félicitations ! Vous avez créé un pipeline CI/CD DevSecOps complet et modulaire ! 🎉**

**Version :** 3.0 (Approche Progressive)
**Dernière mise à jour :** 2025-12-03
**Auteur :** DevSecOps Team
