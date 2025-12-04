# Exercice 7 : Ajouter le Build et Scan Docker

[⬅️ Exercice précédent](Exercice-06.md) | [🏠 Sommaire](README.md) | [Exercice suivant ➡️](Exercice-08.md)

---

## 🎯 Objectif

Construire l'image Docker et la scanner avec Trivy pour détecter les vulnérabilités dans l'image finale. **Approche pédagogique** : expérimenter un blocage réel puis apprendre à gérer les vulnérabilités avec `.trivyignore`.

## ⏱️ Durée Estimée

45 minutes

---

## 📝 Instructions

### Étape 7.1 : Créer le workflow Docker (version simplifiée)

Créez `.github/workflows/build-docker-image.yml` :

```yaml
on:
  workflow_call:
    secrets:
      DEPLOY_APPLI_NAME:
        required: true

permissions:
  security-events: write
  contents: read
  actions: read

jobs:
  build-and-scan-docker:
    name: 🐳 Docker Build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: false
          load: true
          tags: ${{ secrets.DEPLOY_APPLI_NAME }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Run Trivy scan for GitHub Security
        uses: aquasecurity/trivy-action@0.27.0
        with:
          image-ref: ${{ secrets.DEPLOY_APPLI_NAME }}:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH,MEDIUM'

      - name: Upload scan results to GitHub Security
        uses: github/codeql-action/upload-sarif@v4
        if: always()
        with:
          sarif_file: trivy-results.sarif
          category: trivy-container-scan

      - name: Run Trivy scan (display results)
        uses: aquasecurity/trivy-action@0.27.0
        continue-on-error: true
        with:
          image-ref: ${{ secrets.DEPLOY_APPLI_NAME }}:${{ github.sha }}
          format: 'table'
          exit-code: '0'
          severity: 'CRITICAL,HIGH'

      - name: Run Trivy scan (blocking on vulnerabilities)
        uses: aquasecurity/trivy-action@0.27.0
        with:
          image-ref: ${{ secrets.DEPLOY_APPLI_NAME }}:${{ github.sha }}
          format: 'table'
          exit-code: '1'
          ignore-unfixed: true
          severity: 'CRITICAL,HIGH'
```

### Étape 7.2 : Ajouter au pipeline principal

Modifiez `main-pipeline.yml` :

```yaml
  secure-iac-dockerfile-scan:
    needs: build-and-test
    uses: ./.github/workflows/secure-iac-dockerfile-scan.yml

  # ═══════════════════════════════════════════════
  # ÉTAPE 6 : BUILD & SCAN DOCKER
  # ═══════════════════════════════════════════════
  build-and-scan-docker:
    needs: [code-quality-sast, secret-scanning, secure-iac-dockerfile-scan]
    uses: ./.github/workflows/build-docker-image.yml
    secrets: inherit
```

### Étape 7.3 : Premier test (échec attendu !)

```bash
git add .
git commit -m "feat: add Docker build and Trivy scanning"
git push origin main
```

**🎓 Observation attendue** : Le job `build-and-scan-docker` va **échouer** à l'étape "Run Trivy scan (blocking on vulnerabilities)" ! C'est normal et pédagogique.

**Pourquoi ?** Trivy détecte des vulnérabilités CRITICAL/HIGH dans votre image Docker (dépendances Java, packages système, etc.).

**Erreur affichée** :
```
Run Trivy scan (blocking on vulnerabilities)
Error: Process completed with exit code 1.
```

**Ce que vous verrez dans les logs** (étape "display results") :
```
demo-boost-startup-java (java)
Total: X (CRITICAL: Y, HIGH: Z)

┌─────────────────┬────────────────┬──────────┬────────────────┬──────────────┐
│    Library      │ Vulnerability  │ Severity │ Installed Ver  │ Fixed Ver    │
├─────────────────┼────────────────┼──────────┼────────────────┼──────────────┤
│ struts2-core    │ CVE-2023-50164 │ CRITICAL │ 6.3.0          │ 6.3.0.2      │
│ spring-beans    │ CVE-2024-xxxxx │ HIGH     │ 6.1.0          │ 6.1.5        │
└─────────────────┴────────────────┴──────────┴────────────────┴──────────────┘
```

### Étape 7.4 : Analyser les vulnérabilités

Dans les logs GitHub Actions, cherchez l'étape **"Run Trivy scan (display results)"** et notez :
1. Les CVE détectées (ex: CVE-2023-50164, CVE-2024-xxxxx)
2. Leur sévérité (CRITICAL, HIGH)
3. Si elles sont fixables (colonne "Fixed Ver")

### Étape 7.5 : Créer le fichier `.trivyignore`

**Stratégie** : Pour cet exercice pédagogique, vous allez ignorer les vulnérabilités pour débloquer le pipeline. **En production, il faudrait les corriger !**

Créez `.trivyignore` à la racine du projet avec les CVE que vous avez notées :

```bash
cat > .trivyignore << 'EOF'
# Liste des vulnérabilités à ignorer temporairement
# ⚠️ EN PRODUCTION : Corriger ces vulnérabilités au lieu de les ignorer !

# Struts2 - Vulnérabilités connues (liées aux dépendances transitives)
CVE-2012-1592
CVE-2016-3081
CVE-2016-3082
CVE-2016-3087
CVE-2016-4003
CVE-2017-5638
CVE-2017-12611
CVE-2018-11776
CVE-2019-0230
CVE-2019-0233
CVE-2020-17530
CVE-2023-50164

# Spring Framework - Vulnérabilités anciennes
CVE-2016-1000031
CVE-2021-29425

# Autres vulnérabilités à documenter
# Ajoutez ici les CVE spécifiques que Trivy a détectées dans VOS logs
EOF
```

**Important** : Ajustez cette liste selon les CVE **réellement détectées** dans vos logs !

### Étape 7.6 : Mettre à jour le workflow pour utiliser `.trivyignore`

Modifiez `.github/workflows/build-docker-image.yml`, ajoutez `trivyignores:` :

```yaml
      - name: Run Trivy scan (display results)
        uses: aquasecurity/trivy-action@0.27.0
        continue-on-error: true
        with:
          image-ref: ${{ secrets.DEPLOY_APPLI_NAME }}:${{ github.sha }}
          format: 'table'
          exit-code: '0'
          severity: 'CRITICAL,HIGH'
          trivyignores: .trivyignore  # ← AJOUTER

      - name: Run Trivy scan (blocking on vulnerabilities)
        uses: aquasecurity/trivy-action@0.27.0
        with:
          image-ref: ${{ secrets.DEPLOY_APPLI_NAME }}:${{ github.sha }}
          format: 'table'
          exit-code: '1'
          ignore-unfixed: true
          severity: 'CRITICAL,HIGH'
          trivyignores: .trivyignore  # ← AJOUTER
```

### Étape 7.7 : Retester

```bash
git add .trivyignore .github/workflows/build-docker-image.yml
git commit -m "fix: add trivyignore for known vulnerabilities"
git push origin main
```

**🎉 Cette fois, le job `build-and-scan-docker` devrait passer avec succès !**

**Vérifiez** :
- ✅ L'étape "display results" montre les CVE ignorées
- ✅ L'étape "blocking" ne bloque plus (CVE dans `.trivyignore`)
- ✅ Le job GitHub Actions est **vert** (réussi)
- ✅ Les résultats SARIF sont visibles dans **Security → Code scanning**

---

## 🎓 Apprentissage Clé

Cette double expérience intentionnelle démontre :

1. ✅ **Trivy détecte les VRAIES vulnérabilités** : Vous avez vu les CVE réelles dans votre image
2. ✅ **Blocage du pipeline** : Le déploiement est empêché si vulnérabilités critiques
3. ✅ **Gestion avec `.trivyignore`** : Permet d'accepter temporairement des risques connus
4. ✅ **Différence fixable vs non-fixable** : `ignore-unfixed: true` ignore celles sans patch
5. ✅ **Traçabilité** : Chaque CVE ignorée doit être documentée

**Dans un projet réel** :
- Si Trivy détecte une vulnérabilité **FIXABLE** → ⚠️ **CORRIGER** (mettre à jour les dépendances)
- Si elle est **NON FIXABLE** → Évaluer le risque et documenter dans `.trivyignore`
- Utiliser `.trivyignore` uniquement pour **acceptation de risque documentée**

**⚠️ IMPORTANT** : `.trivyignore` est un outil de **gestion du risque**, pas une solution ! Toujours privilégier la correction des vulnérabilités.

---

## ✅ Critères de Validation

- [ ] **Étape 7.3** : Premier push → ❌ Échec avec vulnérabilités détectées
- [ ] **Étape 7.4** : Vous avez analysé les logs et noté les CVE
- [ ] **Étape 7.5** : Création du fichier `.trivyignore`
- [ ] **Étape 7.7** : Deuxième push → ✅ Succès (vulnérabilités ignorées)
- [ ] L'image Docker se construit sans erreur
- [ ] Le cache GitHub Actions fonctionne (build plus rapide au 2e run)
- [ ] Trivy scanne l'image 2 fois (display + blocking)
- [ ] Les résultats SARIF apparaissent dans **Security → Code scanning**
- [ ] Le workflow attend que tous les scans de sécurité soient terminés

---

## 🤔 Questions de Compréhension

1. **Pourquoi 2 scans Trivy dans le workflow ?**
   <details>
   <summary>Voir la réponse</summary>

   **Scan 1 - Display results** (avec `continue-on-error: true`) :
   - Affiche TOUTES les vulnérabilités CRITICAL/HIGH
   - Ne bloque jamais le pipeline
   - Permet de voir ce qui est ignoré

   **Scan 2 - Blocking** (avec `exit-code: '1'`) :
   - Bloque sur les vulnérabilités NON ignorées
   - Applique `.trivyignore`
   - Applique `ignore-unfixed: true`

   **Avantage** : Visibilité complète + contrôle précis du blocage
   </details>

2. **Que signifie `ignore-unfixed: true` ?**
   <details>
   <summary>Voir la réponse</summary>

   Cette option ignore les vulnérabilités **pour lesquelles aucun patch n'existe**.

   **Exemple** :
   - CVE-2024-12345 dans `lib-1.0.0` → Pas de version corrigée → Ignorée
   - CVE-2024-99999 dans `lib-2.0.0` → Version corrigée `2.0.5` → **BLOQUE**

   **Justification** : On ne peut pas corriger ce qui n'a pas de solution, mais on doit corriger ce qui est patchable.
   </details>

3. **Pourquoi cette approche "fail-first" ?**
   <details>
   <summary>Voir la réponse</summary>

   **Objectifs pédagogiques** :
   1. ✅ **Voir Trivy fonctionner** : Détection réelle de vulnérabilités
   2. ✅ **Comprendre le blocage** : Impact sur le pipeline
   3. ✅ **Analyser les résultats** : Lire un rapport Trivy
   4. ✅ **Gérer les risques** : Décider quoi ignorer
   5. ✅ **Utiliser `.trivyignore`** : Outil de gestion du risque

   **Scénario réaliste** : En entreprise, vous rencontrerez des images avec des vulnérabilités. Vous devez savoir les analyser et décider de la stratégie (corriger vs accepter vs ignorer temporairement).
   </details>

4. **Quand faut-il ajouter une CVE à `.trivyignore` ?**
   <details>
   <summary>Voir la réponse</summary>

   ✅ **Cas légitimes** :
   - Vulnérabilité non fixable (`ignore-unfixed` devrait suffire)
   - Faux positif confirmé
   - Vulnérabilité ne s'applique pas à votre contexte (ex: feature non utilisée)
   - Acceptation de risque documentée et approuvée

   ❌ **Mauvaises pratiques** :
   - Ignorer pour "faire passer le build"
   - Ignorer sans analyser la vulnérabilité
   - Ignorer des vulnérabilités fixables
   - Ignorer sans documentation

   **Règle d'or** : Toujours **commenter** dans `.trivyignore` POURQUOI vous ignorez !
   </details>

5. **Comment corriger une vulnérabilité au lieu de l'ignorer ?**
   <details>
   <summary>Voir la réponse</summary>

   **Étapes pour corriger** :

   1. **Identifier la dépendance** :
   ```
   Library: spring-beans
   Installed: 6.1.0
   Fixed: 6.1.5
   ```

   2. **Mettre à jour `pom.xml`** :
   ```xml
   <dependency>
     <groupId>org.springframework</groupId>
     <artifactId>spring-beans</artifactId>
     <version>6.1.5</version>  <!-- ← Mise à jour -->
   </dependency>
   ```

   3. **Tester** :
   ```bash
   mvn clean test
   ```

   4. **Rebuild l'image Docker et rescanner** :
   Le pipeline rebuild automatiquement et Trivy ne détectera plus la CVE !

   **Meilleure pratique** : Toujours privilégier la correction à l'ignore.
   </details>

---

## 🎯 Architecture Actuelle

```
build-and-test
    ├── code-quality-sast ────────┐
    ├── secret-scanning ──────────┼──→ build-and-scan-docker
    └── secure-iac-dockerfile-scan┘       ├── Build image (cache GHA)
                                           ├── Scan SARIF (GitHub Security)
                                           ├── Scan display (toutes CVE)
                                           └── Scan blocking (.trivyignore)
```

**Point de synchronisation !** Le build Docker attend que tous les scans de sécurité soient OK.

---

## 💡 Points Importants

### 🎯 Démarche Pédagogique de cet Exercice

Cet exercice suit une approche **"fail-first"** intentionnelle :

1. **Étape 7.3** : Premier push → ❌ Échec (vulnérabilités détectées)
2. **Étape 7.4** : Analyse des logs Trivy
3. **Étape 7.5** : Création de `.trivyignore`
4. **Étape 7.7** : Deuxième push → ✅ Succès

**Pourquoi cette approche ?**
- ✅ Vous voyez Trivy **détecter de vraies vulnérabilités**
- ✅ Vous apprenez à **lire un rapport Trivy**
- ✅ Vous comprenez **l'impact d'un blocage** sur le pipeline
- ✅ Vous pratiquez la **gestion du risque** avec `.trivyignore`
- ✅ Vous différenciez **corriger vs ignorer**

C'est une situation **réelle** que vous rencontrerez en entreprise !

### Cache Docker avec GitHub Actions

```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

- **Premier build** : ~8-10 minutes
- **Builds suivants** : ~2-3 minutes (gain de 70% !)
- Cache les couches Docker intermédiaires
- `mode=max` : cache toutes les couches (même non utilisées dans le résultat final)

### Gestion des Vulnérabilités : Bonnes Pratiques

✅ **À FAIRE** :
- Analyser chaque vulnérabilité détectée
- Corriger les vulnérabilités fixables (mettre à jour les dépendances)
- Documenter POURQUOI vous ignorez une CVE
- Revoir régulièrement `.trivyignore` (nouvelles versions disponibles ?)
- Consulter la base CVE pour comprendre l'impact

❌ **À ÉVITER** :
- Ignorer aveuglément pour "débloquer le build"
- Utiliser `.trivyignore` comme solution permanente
- Ignorer des vulnérabilités CRITICAL fixables
- Laisser des vulnérabilités sans documentation

---

## 📚 Ressources

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [CVE Database](https://cve.mitre.org/)
- [Docker Build Cache](https://docs.docker.com/build/cache/)
- [Trivy .trivyignore](https://aquasecurity.github.io/trivy/latest/docs/configuration/filtering/#by-finding-ids)

---

## 🎉 Félicitations !

Vous avez maintenant un workflow complet de build et scan Docker qui :
- ✅ Construit l'image avec cache optimisé
- ✅ Détecte les vulnérabilités avec Trivy
- ✅ Bloque le déploiement si vulnérabilités critiques
- ✅ Gère les risques avec `.trivyignore`
- ✅ Upload les résultats dans GitHub Security

Dans l'exercice suivant, vous allez ajouter les tests DAST (tests dynamiques sur l'application déployée).

[Exercice suivant : Tests DAST ➡️](Exercice-08.md)
