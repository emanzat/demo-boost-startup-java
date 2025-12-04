# Exercice 2 : Ajouter le Workflow de Build et Tests

[⬅️ Exercice précédent](Exercice-01.md) | [🏠 Sommaire](README.md) | [Exercice suivant ➡️](Exercice-03.md)

---

## 🎯 Objectif

Créer le premier workflow réutilisable pour compiler et tester l'application Java, puis l'intégrer au pipeline principal.

## ⏱️ Durée Estimée

30 minutes

---

## 📝 Instructions

### Étape 2.1 : Créer le workflow réutilisable

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

### Étape 2.2 : Intégrer au pipeline principal

Modifiez `.github/workflows/main-pipeline.yml` :

**SUPPRIMEZ** le job `placeholder` et **REMPLACEZ-LE** par :

```yaml
jobs:
  # ═══════════════════════════════════════════════
  # ÉTAPE 1 : BUILD & TESTS
  # ═══════════════════════════════════════════════
  build-and-test:
    uses: ./.github/workflows/build-unit-tests.yml
```

Votre `main-pipeline.yml` complet devrait maintenant ressembler à :

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

### Étape 2.3 : Tester

```bash
git add .
git commit -m "feat: add build and unit tests workflow"
git push origin main
```

Allez dans **Actions** et vérifiez que :
- Le workflow `Main CI/CD Pipeline` s'exécute
- Le job `build-and-test` appelle le workflow `Build & Unit Tests`
- Les tests passent
- L'artefact JAR est uploadé

---

## ✅ Critères de Validation

- [ ] Le workflow `build-unit-tests.yml` existe
- [ ] Il utilise `workflow_call` comme déclencheur
- [ ] Le `main-pipeline.yml` appelle ce workflow avec `uses:`
- [ ] La compilation Maven réussit
- [ ] Les tests passent (vérifier les logs)
- [ ] L'artefact JAR est uploadé (vérifier dans l'onglet Artifacts)
- [ ] Le temps d'exécution est d'environ 3-5 minutes

---

## 🤔 Questions de Compréhension

1. **Quelle est la différence entre `workflow_call` et `push` ?**
   <details>
   <summary>Voir la réponse</summary>

   - `workflow_call` : Le workflow peut être appelé par un autre workflow avec `uses:`
   - `push` : Le workflow se déclenche automatiquement sur un push
   - Un workflow peut avoir les deux déclencheurs simultanément
   </details>

2. **Pourquoi utiliser `uses: ./.github/workflows/...` ?**
   <details>
   <summary>Voir la réponse</summary>

   C'est la syntaxe pour appeler un workflow réutilisable dans le même dépôt. Le chemin doit commencer par `./` et pointer vers le fichier workflow.
   </details>

3. **À quoi sert `retention-days: 7` ?**
   <details>
   <summary>Voir la réponse</summary>

   Les artefacts (fichiers uploadés) seront automatiquement supprimés après 7 jours pour économiser l'espace de stockage. Par défaut, GitHub conserve les artefacts pendant 90 jours.
   </details>

4. **Que fait `cache: 'maven'` ?**
   <details>
   <summary>Voir la réponse</summary>

   GitHub Actions met en cache le répertoire `.m2/repository` (dépendances Maven) entre les exécutions. Cela accélère considérablement les builds car les dépendances n'ont pas besoin d'être retéléchargées à chaque fois.
   </details>

5. **Pourquoi `mvn package -DskipTests=true` ?**
   <details>
   <summary>Voir la réponse</summary>

   Les tests ont déjà été exécutés dans l'étape précédente (`mvn test`). On skip les tests lors du package pour éviter de les exécuter deux fois et gagner du temps.
   </details>

---

## 🎯 Architecture Actuelle

```
main-pipeline.yml
    └── build-unit-tests.yml
```

Simple et efficace ! Dans l'exercice suivant, vous allez ajouter l'analyse de sécurité SAST qui s'exécutera en parallèle.

---

## 💡 Points Importants

### Workflows Réutilisables

Un workflow réutilisable :
- Utilise `on: workflow_call:`
- Peut être appelé avec `uses: ./.github/workflows/file.yml`
- Peut accepter des inputs et secrets
- S'exécute comme un job normal dans le workflow appelant

### Bonne Pratique

Chaque workflow réutilisable devrait avoir une **responsabilité unique** (principe SOLID) :
- `build-unit-tests.yml` : Uniquement build et tests
- Pas de déploiement, pas de sécurité, juste le build

---

## 📚 Ressources

- [GitHub Actions - Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [Actions Setup Java](https://github.com/actions/setup-java)
- [Maven Lifecycle](https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html)

---

## 🎉 Félicitations !

Vous avez créé et intégré votre premier workflow réutilisable ! Le pipeline peut maintenant compiler et tester votre application Java.

[Exercice suivant : Analyse SAST ➡️](Exercice-03.md)
