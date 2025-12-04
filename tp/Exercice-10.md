# Exercice 10 : Ajouter le Déploiement en Production

[⬅️ Exercice précédent](Exercice-09.md) | [🏠 Sommaire](README.md) | [Exercice suivant ➡️](Exercice-11.md)

---

## 🎯 Objectif

Déployer automatiquement l'application sur un serveur distant via SSH avec health check automatique.

## ⏱️ Durée Estimée

45 minutes

---

## 📝 Instructions

### Étape 10.1 : Configurer les Secrets SSH

Consultez `.github/SECRETS.md` pour le guide complet de génération des clés SSH.

Dans GitHub : **Settings → Secrets → Actions**, ajoutez :

| Secret | Exemple | Description |
|--------|---------|-------------|
| `DEPLOY_SERVER` | `135.125.223.14` | IP du serveur de déploiement |
| `DEPLOY_SSH_USER` | `ubuntu` | Utilisateur SSH |
| `DEPLOY_SSH_PRIVATE_KEY` | `-----BEGIN OPENSSH...` | Clé privée SSH complète |
| `DEPLOY_SSH_PORT` | `22` | Port SSH (optionnel) |
| `DEPLOY_APPLI_PORT` | `8080` | Port de l'application |
| `DEPLOY_APPLI_NAME` | `demo-boost-startup-java` | Nom du conteneur |

### Étape 10.2 : Créer le workflow de déploiement

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

### Étape 10.3 : Ajouter au pipeline principal

Modifiez `main-pipeline.yml` :

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

### Étape 10.4 : Tester

```bash
git add .
git commit -m "feat: add production deployment with SSH"
git push origin main
```

Vérifiez que l'application est accessible sur votre serveur !

---

## ✅ Critères de Validation

- [ ] La connexion SSH fonctionne
- [ ] L'image Docker est pull depuis Docker Hub
- [ ] L'ancien conteneur est arrêté et supprimé
- [ ] Le nouveau conteneur démarre
- [ ] Le health check réussit (30 tentatives max)
- [ ] Les anciennes images sont nettoyées
- [ ] La clé SSH est supprimée (`if: always()`)
- [ ] L'application est accessible : `http://SERVER_IP:8080/actuator/health`

---

## 🤔 Questions de Compréhension

1. **Pourquoi utiliser un heredoc (`<< 'ENDSSH'`) ?**
   <details>
   <summary>Voir la réponse</summary>

   Le heredoc permet d'exécuter plusieurs commandes SSH en une seule connexion :

   **Sans heredoc** (3 connexions SSH) :
   ```bash
   ssh user@server "docker pull image"
   ssh user@server "docker stop app"
   ssh user@server "docker run ..."
   ```

   **Avec heredoc** (1 seule connexion) :
   ```bash
   ssh user@server << 'EOF'
     docker pull image
     docker stop app
     docker run ...
   EOF
   ```

   **Avantages :**
   - Plus rapide (1 connexion vs 3)
   - Transactions : tout réussit ou tout échoue
   - Moins de surcharge réseau
   </details>

2. **Que fait `--restart unless-stopped` ?**
   <details>
   <summary>Voir la réponse</summary>

   Politiques de redémarrage Docker :
   - `no` : Jamais redémarrer
   - `always` : Toujours redémarrer (même après reboot du serveur)
   - `on-failure` : Redémarrer seulement si exit code != 0
   - `unless-stopped` : Redémarrer sauf si manuellement arrêté

   **`unless-stopped`** est le meilleur choix pour la production :
   - Redémarre automatiquement si crash
   - Redémarre après reboot du serveur
   - Mais respecte les arrêts manuels (maintenance)
   </details>

3. **Comment faire un rollback en cas de problème ?**
   <details>
   <summary>Voir la réponse</summary>

   **Option 1 : Rollback manuel sur le serveur**
   ```bash
   # Se connecter au serveur
   ssh ubuntu@135.125.223.14

   # Lister les images disponibles
   docker images | grep demo-boost-startup-java

   # Arrêter le conteneur actuel
   docker stop demo-boost-startup-java
   docker rm demo-boost-startup-java

   # Démarrer une version précédente
   docker run -d --name demo-boost-startup-java \
     --restart unless-stopped \
     -p 8080:8080 \
     username/demo-boost-startup-java:abc123def  # SHA précédent
   ```

   **Option 2 : Re-déployer un commit précédent**
   ```bash
   # Trouver le commit qui marchait
   git log --oneline

   # Créer une branche de rollback
   git checkout abc123def
   git checkout -b rollback-fix
   git push origin rollback-fix

   # Merger dans main
   gh pr create --title "Rollback to working version"
   ```
   </details>

4. **Pourquoi le health check est-il crucial ?**
   <details>
   <summary>Voir la réponse</summary>

   Sans health check :
   - ❌ L'application peut être démarrée mais non fonctionnelle
   - ❌ Le déploiement serait marqué "réussi" alors qu'il a échoué
   - ❌ Les utilisateurs auraient des erreurs 502/503

   Avec health check :
   - ✅ Vérifie que l'application répond vraiment
   - ✅ Attend que Spring Boot soit complètement initialisé
   - ✅ Échoue le déploiement si l'app ne démarre pas
   - ✅ Détecte les problèmes de configuration

   Le health check est notre **dernière ligne de défense** !
   </details>

---

## 🎯 Architecture Finale

```
[...] → publish-docker-hub
            └── deploy-production-server (main only)
```

Le déploiement est la dernière étape, après que tout soit validé et publié.

---

## 💡 Points Importants

### Sécurité SSH

```yaml
- name: 🔐 Configure SSH
  run: |
    mkdir -p ~/.ssh
    echo "${{ secrets.DEPLOY_SSH_PRIVATE_KEY }}" > ~/.ssh/deploy_key
    chmod 600 ~/.ssh/deploy_key  # ⚠️ OBLIGATOIRE
    ssh-keyscan ... >> ~/.ssh/known_hosts
```

**Important :**
- `chmod 600` : SSH refuse les clés trop permissives
- `ssh-keyscan` : Évite les prompts d'acceptation du host
- Nettoyage avec `if: always()` : Sécurité

### Déploiement Zero-Downtime

Notre déploiement a un **petit downtime** (stop → start).

Pour un déploiement zero-downtime :
1. Blue-Green Deployment (2 instances)
2. Rolling Update (Kubernetes)
3. Health check + load balancer

### Variables d'Environnement

```bash
-e SPRING_PROFILES_ACTIVE=production
```

Permet de charger `application-production.properties` avec :
- Configuration de la base de données de prod
- Logging adapté
- Sécurité renforcée

---

## 📚 Ressources

- [SSH Keys Best Practices](https://www.ssh.com/academy/ssh/keygen)
- [Docker Restart Policies](https://docs.docker.com/config/containers/start-containers-automatically/)
- [Blue-Green Deployment](https://martinfowler.com/bliki/BlueGreenDeployment.html)
- [Spring Boot Profiles](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.profiles)

---

## 🎉 Félicitations !

Votre application est maintenant déployée automatiquement en production ! Dans le dernier exercice, vous allez ajouter des notifications.

[Exercice suivant : Notifications ➡️](Exercice-11.md)
