# Exercice 5 : Ajouter l'Analyse des Dépendances (SCA)

[⬅️ Exercice précédent](Exercice-04.md) | [🏠 Sommaire](README.md) | [Exercice suivant ➡️](Exercice-06.md)

---

## 🎯 Objectif

Identifier les vulnérabilités dans les dépendances Maven (bibliothèques tierces) avec OWASP Dependency-Check.

## ⏱️ Durée Estimée

30 minutes

---

## 📝 Instructions

### Étape 5.1 : Créer le fichier de suppressions

Créez `.owasp-suppressions.xml` à la racine du projet :

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

### Étape 5.2 : Créer le workflow SCA

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
          mvn org.owasp:dependency-check-maven:check \
            -DfailBuildOnCVSS=7 \
            -DsuppressionFiles=.owasp-suppressions.xml

      - name: 📤 Upload Dependency Check SARIF
        uses: github/codeql-action/upload-sarif@v4
        if: always() && hashFiles('target/dependency-check-report.sarif') != ''
        with:
          sarif_file: target/dependency-check-report.sarif
          category: owasp-dependency-check

      - name: 🔍 Run Trivy SCA (filesystem scan)
        uses: aquasecurity/trivy-action@0.27.0
        with:
          scan-type: 'fs'
          format: 'json'
          output: 'trivy-deps-report.json'
          severity: 'CRITICAL,HIGH,MEDIUM'
          ignore-unfixed: true

      - name: 📤 Upload Trivy SCA report
        uses: actions/upload-artifact@v4
        with:
          name: trivy-deps-report
          path: trivy-deps-report.json
          retention-days: 7
```

### Étape 5.3 : Ajouter au pipeline principal

Modifiez `main-pipeline.yml` :

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

### Étape 5.4 : Tester

```bash
git add .
git commit -m "feat: add SCA dependency scanning"
git push origin main
```

---

## ✅ Critères de Validation

- [ ] Le scan OWASP Dependency-Check s'exécute
- [ ] Le scan Trivy SCA (filesystem) s'exécute
- [ ] Le rapport SARIF OWASP est uploadé vers GitHub Security
- [ ] Le rapport JSON Trivy est disponible dans les Artifacts
- [ ] Les résultats apparaissent dans Security → Code scanning
- [ ] Le build échoue si CVSS >= 7
- [ ] S'exécute en parallèle avec SAST et Secret Scanning

---

## 🤔 Questions de Compréhension

1. **Qu'est-ce qu'un score CVSS ?**
   <details>
   <summary>Voir la réponse</summary>

   CVSS (Common Vulnerability Scoring System) est un score de 0 à 10 qui évalue la gravité d'une vulnérabilité :
   - **0.0** : Aucune vulnérabilité
   - **0.1-3.9** : LOW
   - **4.0-6.9** : MEDIUM
   - **7.0-8.9** : HIGH
   - **9.0-10.0** : CRITICAL

   Le score prend en compte : complexité d'exploitation, impact, portée, etc.
   </details>

2. **Pourquoi choisir un seuil de 7 ?**
   <details>
   <summary>Voir la réponse</summary>

   - Un seuil de 7 bloque les vulnérabilités HIGH et CRITICAL
   - C'est un bon équilibre entre sécurité et pragmatisme
   - Les vulnérabilités MEDIUM (< 7) peuvent être traitées plus tard
   - Évite de bloquer le pipeline pour des vulnérabilités mineures
   - Ajustable selon la politique de sécurité de l'entreprise
   </details>

3. **Comment mettre à jour une dépendance vulnérable ?**
   <details>
   <summary>Voir la réponse</summary>

   1. Identifier la dépendance dans le rapport SARIF ou JSON
   2. Dans `pom.xml`, mettre à jour la version :
      ```xml
      <dependency>
        <groupId>com.example</groupId>
        <artifactId>vulnerable-lib</artifactId>
        <version>2.0.0</version> <!-- Version corrigée -->
      </dependency>
      ```
   3. Tester localement : `mvn clean test`
   4. Commit et push
   5. Si pas de version corrigée : ajouter suppression dans `.owasp-suppressions.xml` (temporaire)
   </details>

4. **Qu'est-ce que la base de données NVD ?**
   <details>
   <summary>Voir la réponse</summary>

   NVD (National Vulnerability Database) est la base de données officielle des vulnérabilités :
   - Maintenue par le NIST (US)
   - Contient toutes les CVE (Common Vulnerabilities and Exposures)
   - Mise à jour quotidiennement
   - OWASP Dependency-Check l'utilise pour détecter les vulnérabilités
   </details>

5. **Pourquoi utiliser deux outils SCA (OWASP + Trivy) ?**
   <details>
   <summary>Voir la réponse</summary>

   - **Couverture complémentaire** : Chaque outil a sa propre base de vulnérabilités
   - **OWASP Dependency-Check** : Spécialisé pour Maven/Java, NVD database
   - **Trivy** : Base de données plus large, détection plus rapide
   - **Redondance** : Réduit les faux négatifs (vulnérabilités manquées)
   - **Formats différents** : SARIF pour OWASP, JSON pour Trivy
   </details>

---

## 🎯 Architecture Actuelle

```
build-and-test
    ├── code-quality-sast      (parallèle)
    ├── secret-scanning        (parallèle)
    └── sca-dependency-scan    (parallèle)
```

**3 scans de sécurité en parallèle !** ⚡ Le pipeline est de plus en plus complet.

---

## 💡 Points Importants

### SCA vs SAST

| Aspect | SAST | SCA |
|--------|------|-----|
| Cible | Votre code source | Vos dépendances |
| Détecte | Bugs de sécurité dans votre code | Vulnérabilités connues dans les libs |
| Base | Analyse du code | Base de données CVE |
| Exemple | Injection SQL dans votre code | Log4Shell dans log4j |

### Gestion des Faux Positifs

Le fichier de suppressions permet d'ignorer des vulnérabilités qui ne vous affectent pas :

```xml
<suppress>
  <notes>On n'utilise pas cette fonctionnalité vulnérable</notes>
  <cve>CVE-2023-12345</cve>
</suppress>
```

**Attention** : Documenter **pourquoi** vous supprimez une alerte !

---

## 📚 Ressources

- [OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/)
- [NVD Database](https://nvd.nist.gov/)
- [CVSS Calculator](https://www.first.org/cvss/calculator/3.1)
- [Maven Dependency Tree](https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html)

---

## 🎉 Félicitations !

Votre pipeline détecte maintenant les vulnérabilités dans vos dépendances !

[Exercice suivant : Sécurité IaC ➡️](Exercice-06.md)
