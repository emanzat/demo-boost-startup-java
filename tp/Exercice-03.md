# Exercice 3 : Ajouter l'Analyse SAST

[⬅️ Exercice précédent](Exercice-02.md) | [🏠 Sommaire](README.md) | [Exercice suivant ➡️](Exercice-04.md)

---

## 🎯 Objectif

Ajouter l'analyse de sécurité statique (SAST) avec Semgrep et CodeQL pour détecter les vulnérabilités dans le code source.

## ⏱️ Durée Estimée

45 minutes

---

## 📝 Instructions

### Étape 3.1 : Créer le workflow SAST

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

### Étape 3.2 : Ajouter au pipeline principal

Modifiez `.github/workflows/main-pipeline.yml`, ajoutez après `build-and-test` :

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

### Étape 3.3 : Tester

```bash
git add .
git commit -m "feat: add SAST security scanning"
git push origin main
```

Vérifiez dans **Actions** puis dans **Security → Code scanning alerts**.

---

## ✅ Critères de Validation

- [ ] Semgrep s'exécute et génère un SARIF (même si aucune vulnérabilité)
- [ ] CodeQL analyse le code Java
- [ ] Les résultats apparaissent dans **Security → Code scanning**
- [ ] Le job attend que `build-and-test` soit terminé
- [ ] Le temps d'exécution est d'environ 5-8 minutes

---

## 🤔 Questions de Compréhension

1. **Pourquoi `needs: build-and-test` ?**
   <details>
   <summary>Voir la réponse</summary>

   - `needs:` crée une dépendance entre jobs
   - Le job SAST ne commencera que si `build-and-test` réussit
   - Cela évite de scanner du code qui ne compile pas
   - Optimise l'utilisation des runners
   </details>

2. **Quelle est la différence entre Semgrep et CodeQL ?**
   <details>
   <summary>Voir la réponse</summary>

   **Semgrep:**
   - Basé sur des patterns (regex-like)
   - Rapide et léger
   - Facile à personnaliser
   - Moins de faux positifs

   **CodeQL:**
   - Analyse sémantique approfondie
   - Suit le flux de données (taint analysis)
   - Plus puissant pour les vulnérabilités complexes
   - Plus lent mais plus précis
   </details>

3. **Qu'est-ce qu'un fichier SARIF ?**
   <details>
   <summary>Voir la réponse</summary>

   SARIF (Static Analysis Results Interchange Format) est un format JSON standardisé pour les résultats d'analyse statique. Il permet à GitHub de:
   - Afficher les résultats de manière uniforme
   - Créer des alertes de sécurité
   - Tracker les vulnérabilités au fil du temps
   </details>

4. **Pourquoi `continue-on-error: true` pour Semgrep ?**
   <details>
   <summary>Voir la réponse</summary>

   Si Semgrep trouve des vulnérabilités, il retourne un code d'erreur. `continue-on-error: true` permet:
   - De continuer le workflow même si des vulnérabilités sont trouvées
   - D'uploader quand même les résultats SARIF
   - De ne pas bloquer le pipeline (on veut voir les résultats, pas forcément échouer)
   </details>

---

## 🎯 Architecture Actuelle

```
build-and-test
    └── code-quality-sast
```

Le SAST attend que le build soit terminé avant de s'exécuter. Dans l'exercice suivant, vous ajouterez la détection de secrets qui s'exécutera **en parallèle** avec SAST.

---

## 💡 Points Importants

### Permissions au Niveau Workflow

Les permissions sont définies **dans le workflow réutilisable**, pas dans le pipeline principal :

```yaml
permissions:
  security-events: write  # Nécessaire pour upload SARIF
  contents: read
  actions: read
```

### SAST vs DAST

- **SAST (Static)** : Analyse le code source sans l'exécuter
- **DAST (Dynamic)** : Teste l'application en cours d'exécution
- Les deux sont complémentaires !

---

## 📚 Ressources

- [Semgrep Rules](https://semgrep.dev/explore)
- [CodeQL Queries](https://codeql.github.com/docs/)
- [SARIF Format](https://sarifweb.azurewebsites.net/)
- [OWASP SAST](https://owasp.org/www-community/Source_Code_Analysis_Tools)

---

## 🎉 Félicitations !

Votre pipeline détecte maintenant les vulnérabilités de sécurité dans le code source !

[Exercice suivant : Détection de Secrets ➡️](Exercice-04.md)
