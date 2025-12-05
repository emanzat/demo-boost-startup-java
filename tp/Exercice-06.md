# Exercice 6 : Ajouter la Sécurité IaC (Dockerfile)

[⬅️ Exercice précédent](Exercice-05.md) | [🏠 Sommaire](README.md) | [Exercice suivant ➡️](Exercice-07.md)

---

## 🎯 Objectif

Analyser le Dockerfile pour détecter les mauvaises configurations de sécurité avec Checkov.

## ⏱️ Durée Estimée

30 minutes

---

## 📝 Instructions

### Étape 6.1 : Créer le workflow IaC

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
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: .
          framework: dockerfile
          output_format: sarif
          output_file_path: checkov-report.sarif
          soft_fail: true

      - name: 📤 Upload Checkov SARIF
        uses: github/codeql-action/upload-sarif@v4
        if: always()
        with:
          sarif_file: checkov-report.sarif/results_sarif.sarif
          category: checkov-iac
```

### Étape 6.2 : Ajouter au pipeline principal

Modifiez `main-pipeline.yml` :

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

### Étape 6.3 : (Optionnel) Améliorer le Dockerfile

Si votre Dockerfile n'est pas sécurisé, améliorez-le :

```dockerfile
# ═══════════════════════════════════════
# STAGE 1: Builder
# ═══════════════════════════════════════
FROM bellsoft/liberica-openjdk-alpine:25 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# ═══════════════════════════════════════
# STAGE 2: Runtime
# ═══════════════════════════════════════
FROM bellsoft/liberica-runtime-container:jre-25-slim-musl

# ⚠️ Bonne pratique : Ne pas utiliser root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app/target/*.jar app.jar

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Étape 6.4 : Tester

```bash
git add .
git commit -m "feat: add IaC security scanning for Dockerfile"
git push origin main
```

---

## ✅ Critères de Validation

- [ ] Checkov analyse le Dockerfile
- [ ] Les violations de sécurité sont détectées (si présentes)
- [ ] Les résultats SARIF sont uploadés (dans `checkov-report.sarif/results_sarif.sarif`)
- [ ] Les résultats apparaissent dans Security → Code scanning
- [ ] S'exécute en parallèle avec les autres scans
- [ ] Le workflow ne bloque pas (`soft_fail: true`)
- [ ] L'utilisateur non-root est vérifié
- [ ] Le HEALTHCHECK est validé (si présent)

---

## 🤔 Questions de Compréhension

1. **Pourquoi éviter `USER root` dans Docker ?**
   <details>
   <summary>Voir la réponse</summary>

   - Par défaut, les conteneurs s'exécutent en root
   - Si un attaquant compromet le conteneur, il a les privilèges root
   - Principe de moindre privilège : l'application n'a pas besoin de root
   - Avec un utilisateur non-root :
     - Limite les dégâts en cas de compromission
     - Empêche l'installation de packages malveillants
     - Conforme aux bonnes pratiques de sécurité
   </details>

2. **Quels sont les avantages d'un build multi-stage ?**
   <details>
   <summary>Voir la réponse</summary>

   **Avantages :**
   - Image finale plus petite (seulement le runtime, pas les outils de build)
   - Plus sécurisée (pas de code source, pas de Maven dans l'image finale)
   - Séparation des responsabilités (build vs runtime)
   - Moins de surface d'attaque

   **Exemple :**
   - Stage 1 (builder) : 800 MB avec Maven + JDK
   - Stage 2 (runtime) : 150 MB avec seulement JRE + JAR
   </details>

3. **Que vérifie Checkov exactement sur un Dockerfile ?**
   <details>
   <summary>Voir la réponse</summary>

   Checkov vérifie plus de 50 règles de sécurité :
   - ✅ Utilisation d'un utilisateur non-root (USER)
   - ✅ Présence d'un HEALTHCHECK
   - ✅ Pas de secrets en dur
   - ✅ Image de base récente
   - ✅ Pas de `RUN apt-get upgrade` (anti-pattern)
   - ✅ Utilisation de COPY au lieu de ADD
   - ✅ Port EXPOSE défini
   - Et bien plus...
   </details>

4. **Pourquoi `soft_fail: true` ?**
   <details>
   <summary>Voir la réponse</summary>

   - **`soft_fail: true`** : Le workflow continue même si Checkov trouve des violations
   - Les résultats sont quand même uploadés vers GitHub Security
   - Permet de voir les problèmes sans bloquer le pipeline
   - Utile en phase d'adoption progressive de la sécurité
   - En production stricte, on pourrait mettre `soft_fail: false` pour bloquer
   </details>

5. **Qu'est-ce que l'IaC (Infrastructure as Code) ?**
   <details>
   <summary>Voir la réponse</summary>

   IaC = définir l'infrastructure via du code :
   - Dockerfile → définit l'image du conteneur
   - docker-compose.yml → définit les services
   - Kubernetes YAML → définit les déploiements
   - Terraform → définit l'infrastructure cloud

   **Avantages :**
   - Versionnable (Git)
   - Reproductible
   - Testable (comme notre scan Checkov)
   - Documentation vivante
   </details>

---

## 🎯 Architecture Actuelle

```
build-and-test
    ├── code-quality-sast
    ├── secret-scanning
    ├── sca-dependency-scan
    └── secure-iac-dockerfile-scan
```

**4 scans de sécurité en parallèle !** ⚡⚡⚡

C'est la puissance de l'architecture modulaire : chaque scan est indépendant et s'exécute simultanément.

---

## 💡 Points Importants

### Sécurité par Couches

Notre pipeline implémente la défense en profondeur :

1. **Code source** → SAST (Semgrep + CodeQL)
2. **Secrets** → Gitleaks
3. **Dépendances** → OWASP Dependency-Check
4. **Infrastructure** → Checkov (Dockerfile)
5. **Image** → Trivy (prochain exercice)
6. **Runtime** → DAST (OWASP ZAP)

Chaque couche complémente les autres !

### Checkov vs Autres Outils

| Outil | Cible | Formats |
|-------|-------|---------|
| Checkov | IaC (multi-framework) | Dockerfile, K8s, Terraform, CloudFormation |
| Hadolint | Dockerfile only | Dockerfile |
| Trivy | Images + IaC | Images Docker, K8s, Terraform |

---

## 📚 Ressources

- [Checkov Documentation](https://www.checkov.io/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

---

## 🎉 Félicitations !

Votre Dockerfile est maintenant analysé pour les problèmes de sécurité ! Dans l'exercice suivant, vous allez construire l'image Docker et la scanner avec Trivy.

[Exercice suivant : Build Docker ➡️](Exercice-07.md)
