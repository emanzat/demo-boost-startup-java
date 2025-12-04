# Exercice 4 : Ajouter la Détection de Secrets

[⬅️ Exercice précédent](Exercice-03.md) | [🏠 Sommaire](README.md) | [Exercice suivant ➡️](Exercice-05.md)

---

## 🎯 Objectif

Détecter les secrets (clés API, tokens, mots de passe) accidentellement commités dans le code source et l'historique Git avec Gitleaks.

## ⏱️ Durée Estimée

20 minutes

---

## 📝 Instructions

### Étape 4.1 : Créer le workflow

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

### Étape 4.2 : Ajouter au pipeline principal

Modifiez `main-pipeline.yml`, ajoutez après `code-quality-sast` :

```yaml
  code-quality-sast:
    needs: build-and-test
    uses: ./.github/workflows/code-quality-sast.yml

  # ═══════════════════════════════════════════════
  # ÉTAPE 3 : DÉTECTION DE SECRETS
  # ═══════════════════════════════════════════════
  secret-scanning:
    needs: build-and-test  # ⚠️ S'exécute en PARALLÈLE avec code-quality-sast
    uses: ./.github/workflows/secret-scanning.yml
```

### Étape 4.3 : (Optionnel) Créer une configuration Gitleaks

Pour ignorer les faux positifs, créez `.gitleaks.toml` à la racine :

```toml
title = "Gitleaks Configuration"

[allowlist]
description = "Allowlist for false positives"
paths = [
  '''(^|/)\.gitleaks\.toml$''',
  '''(^|/)\.github/workflows/.*\.yml$''',
]

# Ignorer les secrets de test
regexes = [
  '''EXAMPLE''',
  '''TEST_SECRET''',
]
```

### Étape 4.4 : Tester

```bash
git add .
git commit -m "feat: add secret scanning with Gitleaks"
git push origin main
```

---

## ✅ Critères de Validation

- [ ] Gitleaks scanne tout l'historique Git
- [ ] Le workflow s'exécute **en parallèle** avec `code-quality-sast`
- [ ] Si aucun secret : le job réussit
- [ ] Si secret trouvé : le job échoue (normal)
- [ ] Les deux jobs (SAST + Secrets) démarrent en même temps

---

## 🤔 Questions de Compréhension

1. **Pourquoi `fetch-depth: 0` est crucial ?**
   <details>
   <summary>Voir la réponse</summary>

   - Par défaut, GitHub Actions clone seulement le dernier commit (`fetch-depth: 1`)
   - `fetch-depth: 0` clone **tout l'historique Git**
   - Gitleaks peut ainsi scanner tous les commits passés
   - Important car un secret peut avoir été commité puis supprimé
   </details>

2. **Comment deux jobs peuvent s'exécuter en parallèle ?**
   <details>
   <summary>Voir la réponse</summary>

   Quand deux jobs ont le **même** `needs:`, ils s'exécutent en parallèle :
   ```yaml
   code-quality-sast:
     needs: build-and-test

   secret-scanning:
     needs: build-and-test  # Même dépendance = parallèle
   ```

   Ils démarrent tous les deux dès que `build-and-test` est terminé.
   </details>

3. **Que détecte Gitleaks exactement ?**
   <details>
   <summary>Voir la réponse</summary>

   Gitleaks détecte :
   - Clés API (AWS, GCP, Azure, etc.)
   - Tokens (GitHub, GitLab, Slack, etc.)
   - Mots de passe
   - Clés privées SSH/PGP
   - Credentials de base de données
   - Plus de 100 patterns prédéfinis
   </details>

4. **Que faire si un secret est détecté ?**
   <details>
   <summary>Voir la réponse</summary>

   1. **Révoquer le secret immédiatement** (côté service)
   2. Supprimer le secret du code
   3. **Ne PAS** juste le supprimer du dernier commit
   4. Options :
      - Réécrire l'historique Git (`git filter-branch`)
      - Signaler à GitHub Security
      - Régénérer le secret côté service
   </details>

---

## 🎯 Architecture Actuelle

```
build-and-test
    ├── code-quality-sast    (parallèle)
    └── secret-scanning      (parallèle)
```

**Les deux scans de sécurité s'exécutent maintenant en parallèle !** ⚡

Cela réduit le temps total du pipeline.

---

## 💡 Points Importants

### Exécution Parallèle

```yaml
# Ces deux jobs s'exécutent en parallèle
job-a:
  needs: build

job-b:
  needs: build  # Même dépendance = parallèle
```

```yaml
# Ce job attend que job-a ET job-b soient terminés
job-c:
  needs: [job-a, job-b]  # Séquentiel
```

### Sécurité de l'Historique Git

Un secret commité, même supprimé, reste dans l'historique Git ! C'est pourquoi :
- Gitleaks scanne tout l'historique
- Il faut réécrire l'historique pour vraiment supprimer un secret
- Mieux vaut prévenir que guérir : utiliser des pre-commit hooks

---

## 📚 Ressources

- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [Removing Sensitive Data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

---

## 🎉 Félicitations !

Votre pipeline scanne maintenant le code ET l'historique Git pour détecter les secrets !

[Exercice suivant : Analyse des Dépendances ➡️](Exercice-05.md)
