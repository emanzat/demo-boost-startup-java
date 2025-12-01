# Documentation du Pipeline CI/CD

## Vue d'ensemble

Ce projet implémente un pipeline CI/CD complet avec une approche axée sur la sécurité, suivant les meilleures pratiques DevSecOps.

## Architecture du Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                DÉCLENCHEUR (Push/PR/Planification)              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPE 1: BUILD & TEST                                          │
│  • Compilation du code Java (Maven)                             │
│  • Exécution des tests unitaires                                │
│  • Génération de la couverture de tests                         │
│  • Package JAR                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPE 2: QUALITÉ CODE & SAST (Parallèle)                       │
│  • Analyse SAST Semgrep                                         │
│  • Analyse CodeQL (Java)                                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPES 3-5: ANALYSES DE SÉCURITÉ (Parallèle)                   │
│  • Détection de secrets (Gitleaks)                              │
│  • SCA - Analyse des dépendances (OWASP Dependency-Check)       │
│  • Sécurité IaC (Checkov - Dockerfile)                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPE 6: BUILD IMAGE DOCKER                                    │
│  • Build Docker multi-stage                                     │
│  • Tag avec SHA et branche                                      │
│  • Optimisation du cache                                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPE 7: SCAN IMAGE DOCKER                                     │
│  • Scan de vulnérabilités Trivy                                 │
│  • Échec sur vulnérabilités CRITICAL/HIGH                       │
│  • Upload SARIF vers GitHub Security                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPE 8: DAST (Tests de Sécurité Dynamiques)                   │
│  • Démarrage du conteneur applicatif                            │
│  • Scan OWASP ZAP baseline                                      │
│  • Test de l'application en cours d'exécution                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPE 9: PUBLICATION DOCKER HUB (branche main uniquement)      │
│  • Tag: latest, SHA                                             │
│  • Push vers Docker Hub                                         │
│  • Génération SBOM (Software Bill of Materials)                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  ÉTAPE 10: DÉPLOIEMENT EN PRODUCTION (branche main uniquement)  │
│  • SSH vers serveur 135.125.223.14                              │
│  • Pull de la dernière image                                    │
│  • Arrêt de l'ancien conteneur                                  │
│  • Démarrage du nouveau conteneur                               │
│  • Vérification du health check                                 │
│  • Nettoyage des anciennes images                               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  NOTIFICATION                                                    │
│  • Rapport du statut de déploiement                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Couches de Sécurité

### 1. Tests de Sécurité Applicatifs Statiques (SAST)
- **Semgrep** : Patterns de sécurité rapides et personnalisables
- **CodeQL** : Analyse sémantique approfondie du code Java

### 2. Détection de Secrets
- **Gitleaks** : Détecte les secrets codés en dur, clés API, mots de passe

### 3. Analyse de Composition Logicielle (SCA)
- **OWASP Dependency-Check** : Identifie les dépendances vulnérables
- Échec sur score CVSS >= 7

### 4. Sécurité Infrastructure as Code (IaC)
- **Checkov** : Analyse le Dockerfile pour les mauvaises configurations

### 5. Sécurité des Conteneurs
- **Trivy** : Scan de vulnérabilités multi-couches
- Analyse des packages OS, dépendances applicatives
- Bloque le déploiement sur vulnérabilités CRITICAL/HIGH

### 6. Tests de Sécurité Applicatifs Dynamiques (DAST)
- **OWASP ZAP** : Tests de sécurité à l'exécution
- Teste l'application déployée pour les vulnérabilités

### 7. Génération SBOM
- **Anchore SBOM** : Liste de Matériaux Logiciels
- Suit tous les composants et versions

---

## Déclencheurs du Workflow

| Déclencheur | Quand | Comportement |
|-------------|-------|--------------|
| **Push vers main** | Code fusionné vers la branche main | Pipeline complet + déploiement |
| **Pull Request** | PR ouverte/mise à jour | Pipeline complet (sans déploiement) |
| **Planification** | Lundi 2h du matin (hebdomadaire) | Scans de sécurité uniquement |
| **Manuel** | À la demande via l'interface GitHub | Pipeline complet |

---

## Variables d'Environnement

À configurer dans `.github/workflows/ci-cd-security.yml` :

```yaml
env:
  DOCKER_IMAGE_NAME: demo-boost-startup-java
  DOCKER_REGISTRY: docker.io
  DEPLOY_SERVER: 135.125.223.14
  JAVA_VERSION: '25'
```

---

## Secrets GitHub Requis

Voir [.github/SECRETS.md](.github/SECRETS.md) pour le guide de configuration complet.

**Secrets essentiels :**
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `DEPLOY_SSH_USER`
- `DEPLOY_SSH_PRIVATE_KEY`
- `DEPLOY_SSH_PORT` (optionnel, défaut : 22)

---

## Détail des Étapes du Pipeline

### Étape 1 : Build & Test (3-5 min)
```bash
mvn clean compile
mvn test
mvn jacoco:report
mvn package
```

**Artefacts :**
- `target/*.jar` (JAR de l'application)
- Rapports de couverture de tests

---

### Étape 2 : Qualité Code & SAST (5-8 min)
**Semgrep :**
- Analyse les anti-patterns de sécurité
- Langages : Java, YAML, Dockerfile
- Config : `auto` (rulesets spécifiques au langage)

**CodeQL :**
- Packs de requêtes : `security-extended`, `security-and-quality`
- Suivi de taint approfondi
- Détecte : Injection SQL, XSS, traversée de chemin, etc.

---

### Étape 3 : Détection de Secrets (1-2 min)
**Gitleaks :**
- Analyse l'historique git pour les secrets
- Détecte : Clés API, mots de passe, tokens, clés privées
- Scan complet du dépôt (fetch-depth: 0)

---

### Étape 4 : SCA - Analyse des Dépendances (3-5 min)
**OWASP Dependency-Check :**
- Analyse les dépendances Maven
- Utilise la NVD (National Vulnerability Database)
- Échec sur CVSS >= 7
- Active la détection des dépendances obsolètes

---

### Étape 5 : Sécurité IaC (1-2 min)
**Checkov :**
- Analyse le Dockerfile pour les bonnes pratiques
- Vérifie : Directive USER, secrets exposés, sécurité de l'image de base
- Framework : `dockerfile`

---

### Étape 6 : Build Image Docker (5-10 min)
**Build Docker :**
- Build multi-stage (builder → optimizer → runtime)
- Optimisation du cache BuildKit
- Tags : `latest`, `<branch>-<sha>`, versions sémantiques

**Optimisation du build :**
- Cache des dépendances Maven
- Optimisation des couches
- Image runtime minimale (Liberica Lite)

---

### Étape 7 : Scan Conteneur (2-4 min)
**Trivy :**
- Analyse : Packages OS, bibliothèques applicatives
- Sévérité : CRITICAL, HIGH, MEDIUM
- Upload des résultats vers GitHub Security
- **Bloque le déploiement** si CRITICAL ou HIGH trouvé

---

### Étape 8 : DAST (5-10 min)
**OWASP ZAP Baseline :**
- Démarre le conteneur applicatif
- Scan passif du trafic HTTP
- Tests : `/actuator/health`, points d'API
- Règles personnalisées : `.zap/rules.tsv`

---

### Étape 9 : Publication Image (2-3 min)
**Docker Hub :**
- Connexion avec authentification par token
- Push des tags : `latest`, `<sha>`
- Génération SBOM (format SPDX)

---

### Étape 10 : Déploiement (1-2 min)
**Déploiement SSH :**
```bash
docker pull username/demo-boost-startup-java:latest
docker stop demo-boost-startup-java
docker rm demo-boost-startup-java
docker run -d --name demo-boost-startup-java \
  --restart unless-stopped \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=production \
  username/demo-boost-startup-java:latest
```

**Health check :**
```bash
curl http://localhost:8080/actuator/health
```

**Nettoyage :**
```bash
docker image prune -af --filter "until=24h"
```

---

## Durée Totale du Pipeline

| Scénario | Durée |
|----------|-------|
| **PR (sans déploiement)** | ~20-30 min |
| **Push vers main (complet)** | ~30-45 min |
| **Build en cache** | ~15-25 min |

---

## Intégration GitHub Security

Tous les résultats de sécurité sont uploadés vers **GitHub Security → Code Scanning** :

- SARIF Semgrep
- Résultats CodeQL
- SARIF OWASP Dependency-Check
- SARIF Checkov
- SARIF Trivy

Voir à : `https://github.com/<org>/<repo>/security/code-scanning`

---

## Surveillance & Alertes

### Badge de Statut du Build
Ajouter au README.md :
```markdown
![Pipeline CI/CD](https://github.com/<org>/<repo>/actions/workflows/ci-cd-security.yml/badge.svg)
```

### Notifications d'Échec de Build
- GitHub enverra des notifications par email en cas d'échec
- Configurer dans : Settings → Notifications

### Alertes de Sécurité
- Activer : Settings → Security → Dependabot alerts
- Configurer : Settings → Security → Code scanning alerts

---

## Procédure de Rollback

Si le déploiement échoue ou introduit des problèmes :

```bash
# SSH vers le serveur
ssh deploy@135.125.223.14

# Lister les images disponibles
docker images | grep demo-boost-startup-java

# Arrêter le conteneur actuel
docker stop demo-boost-startup-java
docker rm demo-boost-startup-java

# Exécuter la version précédente (remplacer <previous-sha> avec le SHA actuel)
docker run -d --name demo-boost-startup-java \
  --restart unless-stopped \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=production \
  username/demo-boost-startup-java:<previous-sha>

# Vérifier
curl http://localhost:8080/actuator/health
```

---

## Tests Locaux

### Tester le build Docker localement :
```bash
docker build -t demo-boost-startup-java:local .
docker run -p 8080:8080 demo-boost-startup-java:local
```

### Tester les scans de sécurité localement :
```bash
# SAST avec Semgrep
docker run --rm -v "${PWD}:/src" returntocorp/semgrep semgrep --config=auto

# Scan de secrets avec Gitleaks
docker run --rm -v "${PWD}:/path" zricethezav/gitleaks:latest detect --source="/path" -v

# Scan de conteneur avec Trivy
trivy image demo-boost-startup-java:local
```

---

## Conseils d'Optimisation

1. **Cache des Dépendances :**
   - GitHub Actions cache les dépendances Maven
   - Docker BuildKit cache les couches

2. **Jobs Parallèles :**
   - Les scans de sécurité s'exécutent en parallèle (étapes 3-5)
   - Réduit le temps total du pipeline d'environ 10 minutes

3. **Exécution Conditionnelle :**
   - DAST uniquement sur push/schedule (pas les PRs)
   - Déploiement uniquement sur la branche main

4. **Fail Fast :**
   - Les tests unitaires s'exécutent en premier
   - Les scans de sécurité critiques bloquent le déploiement

---

## Dépannage

### Problèmes Courants

**1. Le build échoue à l'étape de test :**
```bash
# Vérifier les logs de test dans GitHub Actions
# Exécuter les tests localement :
mvn clean test
```

**2. Un scan de sécurité bloque le déploiement :**
- Consulter les résultats dans l'onglet Security de GitHub
- Corriger les vulnérabilités dans le code/dépendances
- Mettre à jour les dépendances vulnérables dans `pom.xml`

**3. Le build Docker échoue :**
```bash
# Vérifier la syntaxe du Dockerfile
docker build --no-cache -t test .

# Consulter les logs de build dans Actions
```

**4. Le déploiement échoue :**
- Vérifier la connexion SSH : `ssh deploy@135.125.223.14`
- Vérifier l'espace disque du serveur : `df -h`
- Vérifier que l'image Docker Hub existe
- Consulter les logs du serveur : `docker logs demo-boost-startup-java`

**5. Le scan DAST échoue :**
- Vérifier que l'application démarre correctement
- Vérifier le point de terminaison health : `/actuator/health`
- Consulter les règles ZAP dans `.zap/rules.tsv`

---

## Bonnes Pratiques

1. **Sécurité :**
   - Ne jamais commiter de secrets
   - Faire une rotation régulière des clés SSH
   - Consulter les résultats de sécurité chaque semaine

2. **Tests :**
   - Maintenir >80% de couverture de code
   - Écrire des tests d'intégration
   - Tester localement avant de pusher

3. **Déploiement :**
   - Utiliser le versioning sémantique pour les releases
   - Tagger les releases dans GitHub
   - Documenter les changements cassants

4. **Surveillance :**
   - Surveiller les logs applicatifs
   - Configurer des alertes de health check
   - Suivre les métriques de déploiement

---

## Ressources Additionnelles

- [Documentation GitHub Actions](https://docs.github.com/en/actions)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Bonnes Pratiques de Sécurité Docker](https://docs.docker.com/develop/security-best-practices/)
- [Documentation Trivy](https://aquasecurity.github.io/trivy/)
- [Règles Semgrep](https://semgrep.dev/r)

---

## Support

Pour les problèmes avec le pipeline :
1. Vérifier les logs GitHub Actions
2. Consulter cette documentation
3. Voir `.github/SECRETS.md` pour la configuration
4. Contacter l'équipe DevOps

---

**Version du Pipeline :** 1.0
**Dernière Mise à Jour :** 2025-12-01
**Mainteneur :** Équipe DevOps
