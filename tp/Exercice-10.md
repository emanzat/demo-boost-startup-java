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
on:
  workflow_call:
    secrets:
      DEPLOY_SERVER:
        required: true
      DEPLOY_SSH_USER:
        required: true
      DEPLOY_SSH_PRIVATE_KEY:
        required: true
      DEPLOY_SSH_PORT:
        required: false
      DOCKERHUB_USERNAME:
        required: true
      DEPLOY_APPLI_PORT:
        required: true
      DEPLOY_APPLI_NAME:
        required: true
      MONGODB_COLLECTION_NAME:
        required: false

jobs:
  deploy-production-server:
    name: 🚀 Deploy
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to server via SSH
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.DEPLOY_SERVER }}
          username: ${{ secrets.DEPLOY_SSH_USER }}
          key: ${{ secrets.DEPLOY_SSH_PRIVATE_KEY }}
          port: ${{ secrets.DEPLOY_SSH_PORT || 22 }}
          script: |
            docker pull ${{ secrets.DOCKERHUB_USERNAME }}/${{ secrets.DEPLOY_APPLI_NAME }}:latest
            docker stop ${{ secrets.DEPLOY_APPLI_NAME }} || true
            docker rm ${{ secrets.DEPLOY_APPLI_NAME }} || true
            docker run -d --name ${{ secrets.DEPLOY_APPLI_NAME }} \
              -p ${{ secrets.DEPLOY_APPLI_PORT }}:8080 \
              -e MONGODB_COLLECTION_NAME=${{ secrets.MONGODB_COLLECTION_NAME || 'persons' }} \
              --network app-network \
              ${{ secrets.DOCKERHUB_USERNAME }}/${{ secrets.DEPLOY_APPLI_NAME }}:latest
            sleep 10
            curl -f http://localhost:8080/actuator/health || exit 1
            docker image prune -af --filter "until=24h"

      - name: Verify deployment
        run: |
          curl -f http://${{ secrets.DEPLOY_SERVER }}:8080/actuator/health
```

### Étape 10.3 : Ajouter au pipeline principal

Modifiez `main-pipeline.yml` :

```yaml
  dast-dynamic-security-testing:
    needs: publish-docker-hub
    uses: ./.github/workflows/dast-zap-test.yml
    secrets: inherit

  # ═══════════════════════════════════════════════
  # ÉTAPE 9 : DÉPLOIEMENT EN PRODUCTION
  # ═══════════════════════════════════════════════
  deploy-production-server:
    needs: dast-dynamic-security-testing
    uses: ./.github/workflows/deploy-production-server.yml
    secrets: inherit
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

- [ ] Utilise `appleboy/ssh-action@v1.0.3` pour le déploiement SSH
- [ ] L'image Docker est pull depuis Docker Hub
- [ ] L'ancien conteneur est arrêté et supprimé (avec `|| true`)
- [ ] Le nouveau conteneur démarre avec `--network app-network`
- [ ] La variable `MONGODB_COLLECTION_NAME` est passée (défaut: `persons`)
- [ ] Le health check réussit après 10 secondes
- [ ] Les anciennes images sont nettoyées (< 24h)
- [ ] Vérification externe du deployment depuis GitHub Actions
- [ ] L'application est accessible : `http://SERVER_IP:8080/actuator/health`

---

## 🤔 Questions de Compréhension

1. **Pourquoi utiliser `appleboy/ssh-action` au lieu de SSH manuel ?**
   <details>
   <summary>Voir la réponse</summary>

   **Avantages de `appleboy/ssh-action` :**
   - **Plus simple** : Pas besoin de gérer manuellement les clés SSH
   - **Sécurisé** : Gestion automatique des permissions (chmod 600)
   - **Pas de cleanup** : Pas de clé SSH résiduelle à nettoyer
   - **Meilleure gestion des erreurs** : Sortie claire et structurée
   - **Script multiline** : Paramètre `script` facile à lire
   - **SSH keyscan automatique** : Évite les prompts d'acceptation du host

   **Comparaison :**
   ```yaml
   # Approche manuelle (complexe)
   - run: |
       mkdir -p ~/.ssh
       echo "$KEY" > ~/.ssh/key
       chmod 600 ~/.ssh/key
       ssh-keyscan ... >> ~/.ssh/known_hosts
       ssh -i ~/.ssh/key user@server "commands"
       rm -f ~/.ssh/key

   # Avec appleboy (simple)
   - uses: appleboy/ssh-action@v1.0.3
     with:
       host: ${{ secrets.DEPLOY_SERVER }}
       username: ${{ secrets.DEPLOY_SSH_USER }}
       key: ${{ secrets.DEPLOY_SSH_PRIVATE_KEY }}
       script: commands
   ```
   </details>

2. **Pourquoi `--network app-network` ?**
   <details>
   <summary>Voir la réponse</summary>

   Le conteneur Spring Boot doit communiquer avec MongoDB :

   **Sans network Docker :**
   ```bash
   # Impossible de résoudre "mongodb" comme hostname
   docker run -e MONGODB_URI=mongodb://mongodb:27017/demo app
   # ❌ UnknownHostException: mongodb
   ```

   **Avec network Docker :**
   ```bash
   # Le réseau Docker permet la résolution DNS interne
   docker network create app-network
   docker run --name mongodb --network app-network mongo:7
   docker run --name app --network app-network \
     -e MONGODB_URI=mongodb://mongodb:27017/demo app
   # ✅ La connexion fonctionne!
   ```

   **Avantages :**
   - Résolution DNS automatique entre conteneurs
   - Communication sécurisée (réseau interne)
   - Isolation du trafic réseau
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

   **Notre approche en deux étapes :**
   1. `sleep 10` + health check sur le serveur (via SSH)
   2. Vérification externe depuis GitHub Actions

   Le health check est notre **dernière ligne de défense** !
   </details>

5. **Pourquoi déclarer explicitement tous les secrets dans `workflow_call` ?**
   <details>
   <summary>Voir la réponse</summary>

   **Avec déclaration explicite (notre approche) :**
   ```yaml
   on:
     workflow_call:
       secrets:
         DEPLOY_SERVER:
           required: true
         DEPLOY_SSH_USER:
           required: true
         # ... etc
   ```

   **Avantages :**
   - ✅ Documentation claire : On sait exactement quels secrets sont nécessaires
   - ✅ Validation automatique : GitHub vérifie que tous les secrets requis sont présents
   - ✅ Sécurité : Principe du moindre privilège (seuls les secrets déclarés sont accessibles)
   - ✅ Maintenabilité : Si un secret est manquant, erreur explicite avant exécution

   **Alternative avec `secrets: inherit` seulement :**
   ```yaml
   on:
     workflow_call:
   # Pas de déclaration - tous les secrets sont hérités
   ```
   - ❌ Moins clair : On ne sait pas quels secrets sont nécessaires
   - ❌ Pas de validation : Erreur seulement à l'exécution
   - ❌ Moins sécurisé : Tous les secrets du repo sont accessibles

   **Best practice :** Toujours déclarer explicitement les secrets nécessaires !
   </details>

---

## 🎯 Architecture Finale

```
publish-docker-hub
    └── dast-dynamic-security-testing
            └── deploy-production-server
```

Le déploiement est la dernière étape, après que tout soit validé, publié et testé dynamiquement.

---

## 💡 Points Importants

### Utilisation de `appleboy/ssh-action`

```yaml
- uses: appleboy/ssh-action@v1.0.3
  with:
    host: ${{ secrets.DEPLOY_SERVER }}
    username: ${{ secrets.DEPLOY_SSH_USER }}
    key: ${{ secrets.DEPLOY_SSH_PRIVATE_KEY }}
    port: ${{ secrets.DEPLOY_SSH_PORT || 22 }}
    script: |
      # Commandes à exécuter sur le serveur distant
```

**Avantages :**
- Gestion automatique de la sécurité SSH (chmod 600, keyscan)
- Pas de cleanup manuel nécessaire
- Script multiline clair et lisible

### Réseau Docker

```bash
--network app-network
```

Le conteneur Spring Boot et MongoDB communiquent via un réseau Docker :
- Résolution DNS interne (`mongodb` → adresse IP du conteneur)
- Isolation réseau
- Communication sécurisée

### Variables d'Environnement

```bash
-e MONGODB_COLLECTION_NAME=${{ secrets.MONGODB_COLLECTION_NAME || 'persons' }}
```

Configuration de l'application :
- Collection MongoDB dynamique
- Valeur par défaut : `persons`
- Permet différentes configurations par environnement

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
