# Guide de Dépannage - Pipeline CI/CD

[🏠 Retour au sommaire](README.md)

---

## 🐛 Problèmes Courants et Solutions

### Workflows Réutilisables

#### ❌ Erreur : "workflow_call event is not available"

**Cause :** Le workflow n'a pas `on: workflow_call:`

**Solution :**
```yaml
# ❌ Incorrect
on:
  push:
    branches: [main]

# ✅ Correct
on:
  workflow_call:
```

---

#### ❌ Erreur : "secret not found"

**Cause :** Le workflow réutilisable n'a pas accès aux secrets

**Solution :**
```yaml
# Dans main-pipeline.yml
my-job:
  uses: ./.github/workflows/my-workflow.yml
  secrets: inherit  # ⚠️ OBLIGATOIRE
```

---

#### ❌ Erreur : "artifact not found"

**Cause :** Le job précédent n'a pas uploadé l'artefact ou il a expiré

**Solutions :**
1. Vérifier que l'upload fonctionne :
```yaml
- uses: actions/upload-artifact@v4
  with:
    name: docker-image  # ⚠️ Même nom exact
    path: /tmp/docker-image.tar
```

2. Vérifier le download :
```yaml
- uses: actions/download-artifact@v4
  with:
    name: docker-image  # ⚠️ Même nom exact
    path: /tmp
```

3. Vérifier que `retention-days` n'est pas expiré

---

### Jobs et Dépendances

#### ❌ Job skippé de manière inattendue

**Causes possibles :**
1. Condition `if:` non remplie
2. Job précédent a échoué

**Debug :**
```yaml
# Vérifier les conditions
my-job:
  if: github.ref == 'refs/heads/main'  # Ne s'exécute que sur main
  needs: previous-job
```

**Solutions :**
- Vérifier la branche courante
- Utiliser `if: always()` pour ignorer les échecs précédents
- Consulter les logs pour voir pourquoi le job est skippé

---

#### ❌ Jobs ne s'exécutent pas en parallèle

**Cause :** Dépendances `needs:` incorrectes

**Problème :**
```yaml
# ❌ Séquentiel
job-a:
  needs: build

job-b:
  needs: job-a  # Attend job-a !
```

**Solution :**
```yaml
# ✅ Parallèle
job-a:
  needs: build

job-b:
  needs: build  # Même dépendance = parallèle
```

---

### Maven et Java

#### ❌ Erreur : "package does not exist"

**Cause :** Dépendances non téléchargées ou cache corrompu

**Solutions :**
```yaml
- name: Setup Java
  uses: actions/setup-java@v4
  with:
    cache: 'maven'  # ⚠️ Important

# Si le cache est corrompu, forcer le re-download
- run: mvn clean install -U  # -U force update
```

---

#### ❌ Erreur : "tests failed"

**Debug local :**
```bash
# Exécuter les tests localement
mvn clean test

# Verbose pour plus de détails
mvn clean test -X

# Skip un test spécifique
mvn test -Dtest='!MyFailingTest'
```

---

### Docker

#### ❌ Erreur : "docker: command not found"

**Cause :** Docker n'est pas installé sur le runner

**Solution :**
```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3  # ⚠️ Nécessaire
```

---

#### ❌ Erreur : "failed to load image"

**Cause :** Le fichier tar est corrompu ou incomplet

**Solutions :**
1. Vérifier la taille du fichier :
```yaml
- run: ls -lh /tmp/docker-image.tar
```

2. Vérifier que le save a réussi :
```yaml
- name: Save Docker image
  run: |
    docker save image:latest -o /tmp/image.tar
    ls -lh /tmp/image.tar  # Doit être > 100MB
```

---

#### ❌ Erreur : "manifest unknown"

**Cause :** L'image n'existe pas localement

**Solution :**
```yaml
# S'assurer que l'image est bien construite
- name: Build Docker image
  uses: docker/build-push-action@v5
  with:
    load: true  # ⚠️ Important : charge l'image dans Docker
```

---

### SSH et Déploiement

#### ❌ Erreur : "Permission denied (publickey)"

**Causes possibles :**
1. Clé privée incorrecte
2. Permissions de la clé incorrectes
3. Clé publique non ajoutée sur le serveur

**Solutions :**
```yaml
# 1. Vérifier les permissions
- run: |
    chmod 600 ~/.ssh/deploy_key  # ⚠️ OBLIGATOIRE
    ls -la ~/.ssh/deploy_key

# 2. Tester la connexion
- run: |
    ssh -i ~/.ssh/deploy_key -v \
      user@server "echo 'Connection OK'"
```

**Sur le serveur :**
```bash
# Vérifier que la clé publique est bien présente
cat ~/.ssh/authorized_keys

# Vérifier les permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

#### ❌ Erreur : "Host key verification failed"

**Cause :** Le host n'est pas dans known_hosts

**Solution :**
```yaml
- run: |
    ssh-keyscan -p 22 server-ip >> ~/.ssh/known_hosts
```

---

#### ❌ Health check échoue après déploiement

**Debug :**
```bash
# Se connecter au serveur
ssh user@server

# Vérifier que le conteneur tourne
docker ps -a

# Voir les logs
docker logs demo-boost-startup-java

# Tester manuellement le health check
curl http://localhost:8080/actuator/health

# Vérifier les ports
netstat -tulpn | grep 8080
```

**Causes courantes :**
- L'application met trop de temps à démarrer (augmenter le timeout)
- Port déjà utilisé
- Configuration incorrecte
- Base de données non accessible

---

### Trivy et Scans de Sécurité

#### ❌ Trivy bloque le pipeline

**Cause :** Vulnérabilités CRITICAL ou HIGH détectées

**Solutions :**

1. **Corriger les vulnérabilités** (recommandé) :
```bash
# Mettre à jour l'image de base
FROM bellsoft/liberica-runtime-container:jre-25-slim-musl

# Mettre à jour les dépendances
mvn versions:use-latest-releases
```

2. **Temporaire : Réduire le seuil** (non recommandé) :
```yaml
- uses: aquasecurity/trivy-action@master
  with:
    severity: 'CRITICAL'  # Seulement CRITICAL
    exit-code: '0'  # ⚠️ Ne bloque plus
```

---

#### ❌ OWASP Dependency-Check échoue

**Cause :** CVSS >= 7 détecté

**Solutions :**

1. **Mettre à jour la dépendance** (recommandé) :
```xml
<!-- Dans pom.xml -->
<dependency>
  <groupId>com.example</groupId>
  <artifactId>vulnerable-lib</artifactId>
  <version>2.0.0</version> <!-- Version corrigée -->
</dependency>
```

2. **Supprimer temporairement** (à documenter) :
```xml
<!-- Dans .github/dependency-check-suppressions.xml -->
<suppress>
  <notes>Faux positif - ne concerne pas notre usage</notes>
  <cve>CVE-2023-12345</cve>
</suppress>
```

---

### DAST et OWASP ZAP

#### ❌ ZAP ne peut pas atteindre l'application

**Debug :**
```yaml
- name: Test connectivity
  run: |
    docker ps  # Vérifier que le conteneur tourne
    curl -v http://localhost:8080/actuator/health
    docker logs test-app  # Voir les logs
```

**Cause courante :** L'application n'a pas fini de démarrer

**Solution :**
```yaml
# Augmenter le timeout
for i in {1..60}; do  # 60 au lieu de 30
  if curl -f http://localhost:8080/actuator/health; then
    break
  fi
  sleep 3  # 3 secondes au lieu de 2
done
```

---

### Permissions GitHub

#### ❌ Erreur : "Resource not accessible by integration"

**Cause :** Permissions insuffisantes

**Solution :**
```yaml
# Dans le workflow réutilisable
permissions:
  security-events: write  # Pour upload SARIF
  contents: read         # Pour checkout
  actions: read          # Pour artifacts
```

**Dans main-pipeline.yml :**
```yaml
permissions:
  security-events: write
  contents: read
  actions: read
```

---

## 🔍 Commandes de Debug Utiles

### Vérifier l'état du pipeline

```bash
# Lister les workflows
gh workflow list

# Voir les runs d'un workflow
gh run list --workflow=main-pipeline.yml

# Voir les logs d'un run
gh run view RUN_ID --log

# Télécharger les artefacts
gh run download RUN_ID
```

### Debug local

```bash
# Simuler le build complet
mvn clean verify

# Tester Docker localement
docker build -t test:latest .
docker run -p 8080:8080 test:latest

# Tester Trivy localement
trivy image test:latest

# Tester Semgrep localement
docker run --rm -v "${PWD}:/src" \
  returntocorp/semgrep semgrep --config=auto
```

---

## 📞 Besoin d'Aide ?

1. ✅ Consulter les logs dans **Actions**
2. ✅ Vérifier ce guide de dépannage
3. ✅ Tester localement avec les commandes ci-dessus
4. ✅ Consulter la documentation officielle
5. ✅ Demander à l'équipe DevOps

---

## 📚 Ressources

- [GitHub Actions Troubleshooting](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows)
- [Docker Troubleshooting](https://docs.docker.com/config/daemon/)
- [Maven Troubleshooting](https://maven.apache.org/guides/mini/guide-debugging.html)

---

[🏠 Retour au sommaire](README.md)
