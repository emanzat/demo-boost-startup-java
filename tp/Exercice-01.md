# Exercice 1 : Créer le Pipeline Principal (Squelette)

[🏠 Retour au sommaire](README.md) | [Exercice suivant ➡️](Exercice-02.md)

---

## 🎯 Objectif

Créer le workflow principal `main-pipeline.yml` qui servira d'orchestrateur. Nous allons le remplir progressivement au fur et à mesure des exercices.

## ⏱️ Durée Estimée

20 minutes

---

## 📝 Instructions

### Étape 1.1 : Créer la structure de base

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

### Étape 1.2 : Comprendre la structure

#### Déclencheurs (`on:`)

- `push: branches: [main]` : Se déclenche sur chaque push vers main
- `pull_request: branches: [main]` : Se déclenche sur les PRs vers main
- `schedule: cron` : Exécution planifiée (chaque lundi à 2h)
- `workflow_dispatch` : Permet de lancer manuellement le workflow

#### Permissions

- `security-events: write` : Pour uploader les résultats SARIF vers GitHub Security
- `contents: read` : Pour lire le code du repository
- `actions: read` : Pour lire les workflows

### Étape 1.3 : Commiter et tester

```bash
git add .github/workflows/main-pipeline.yml
git commit -m "feat: add main pipeline skeleton"
git push origin main
```

Allez dans **Actions** → Vous devriez voir le workflow s'exécuter !

---

## ✅ Critères de Validation

- [ ] Le fichier `main-pipeline.yml` est créé dans `.github/workflows/`
- [ ] Le workflow apparaît dans l'onglet "Actions" de GitHub
- [ ] Le job `placeholder` s'exécute avec succès
- [ ] Vous voyez la liste des exercices à venir dans les logs
- [ ] Vous comprenez les 4 types de déclencheurs

---

## 🤔 Questions de Compréhension

1. **Quelle est la différence entre `push` et `pull_request` ?**
   <details>
   <summary>Voir la réponse</summary>

   - `push` : Se déclenche quand du code est poussé directement sur la branche
   - `pull_request` : Se déclenche quand une Pull Request est créée ou mise à jour
   - Sur une PR, les deux peuvent se déclencher (push sur la branche de la PR + événement PR)
   </details>

2. **À quoi sert `workflow_dispatch` ?**
   <details>
   <summary>Voir la réponse</summary>

   Permet de déclencher manuellement le workflow depuis l'interface GitHub Actions, utile pour :
   - Tester le pipeline sans faire de commit
   - Relancer un déploiement
   - Exécuter des tâches à la demande
   </details>

3. **Pourquoi avons-nous besoin de `security-events: write` ?**
   <details>
   <summary>Voir la réponse</summary>

   Cette permission est nécessaire pour uploader les fichiers SARIF (résultats de sécurité) vers l'onglet Security de GitHub. Sans cette permission, les scans de sécurité ne pourront pas publier leurs résultats.
   </details>

4. **Que se passe-t-il si on commente `schedule:` ?**
   <details>
   <summary>Voir la réponse</summary>

   Le pipeline ne s'exécutera plus automatiquement chaque lundi. Il ne se déclenchera que sur push, PR ou manuellement.
   </details>

---

## 🎯 Architecture Actuelle

À cette étape, votre pipeline ressemble à :

```
main-pipeline.yml
    └── placeholder (job temporaire)
```

Ce job sera supprimé dans l'exercice 2 et remplacé par de vrais workflows réutilisables.

---

## 📚 Ressources

- [GitHub Actions - Événements déclencheurs](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows)
- [GitHub Actions - Permissions](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#permissions)

---

## 🎉 Félicitations !

Vous avez créé la base de votre pipeline CI/CD. Dans l'exercice suivant, vous allez ajouter le premier workflow réutilisable pour le build et les tests.

[Exercice suivant : Build et Tests ➡️](Exercice-02.md)
