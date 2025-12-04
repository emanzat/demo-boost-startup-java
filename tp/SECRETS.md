# Guide de Configuration des Secrets GitHub

Ce document liste tous les Secrets GitHub requis pour que le pipeline CI/CD fonctionne correctement.

---

## 🔀 Étape 0 : Fork du Projet

**Avant toute configuration, vous devez fork le projet :**

1. Allez sur https://github.com/emanzat/demo-boost-startup-java
2. Cliquez sur le bouton **"Fork"** en haut à droite
3. Créez le fork dans votre compte GitHub personnel ou organisation
4. Clonez votre fork sur votre machine locale :
   ```bash
   git clone https://github.com/VOTRE_USERNAME/demo-boost-startup-java.git
   cd demo-boost-startup-java
   ```

**⚠️ Important** : Toutes les configurations suivantes doivent être effectuées dans **votre fork**, pas dans le dépôt original.

---

## 🔐 Secrets Requis

Configurez ces secrets dans **votre dépôt forké** :
`Settings` → `Secrets and variables` → `Actions` → `New repository secret`

### Authentification Docker Hub

| Nom du Secret | Description | Exemple |
|---------------|-------------|---------|
| `DOCKERHUB_USERNAME` | Votre nom d'utilisateur Docker Hub | `monusername` |
| `DOCKERHUB_TOKEN` | Token d'accès Docker Hub (PAS le mot de passe) | Générer sur https://hub.docker.com/settings/security |

**Comment créer un token Docker Hub :**
1. Allez sur https://hub.docker.com/settings/security
2. Cliquez sur "New Access Token"
3. Nommez-le "GitHub Actions CI/CD"
4. Copiez le token et enregistrez-le comme secret `DOCKERHUB_TOKEN`

---

### Configuration du Déploiement SSH

| Nom du Secret | Description | Exemple | Valeur |
|---------------|-------------|---------|--------|
| `DEPLOY_SERVER` | Adresse IP ou nom d'hôte du serveur de déploiement | `135.125.223.14` | `` |
| `DEPLOY_SSH_USER` | Nom d'utilisateur SSH pour le serveur de déploiement | `ubuntu` | - |
| `DEPLOY_SSH_PRIVATE_KEY` | Clé privée SSH pour l'authentification | Contenu complet de la clé privée (voir ci-dessous) | - |
| `DEPLOY_SSH_PORT` | Port SSH (optionnel, par défaut 22) | `22` ou `2222` | - |
| `DEPLOY_APPLI_PORT` | Port de l'application à exposer sur le serveur | `8080` | - |
| `DEPLOY_APPLI_NAME` | Nom de l'application/conteneur pour le déploiement | `demo-boost-startup-java` | - |
| `MONGODB_COLLECTION_NAME` | Nom de la collection MongoDB pour les personnes (optionnel, par défaut "persons") | `persons` ou `users` | - |

**Comment générer une paire de clés SSH :**

```bash
# Sur votre machine locale, générez une nouvelle paire de clés SSH
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/deploy_key

# Copiez la clé PUBLIQUE sur votre serveur de déploiement
ssh-copy-id -i ~/.ssh/deploy_key.pub ubuntu@135.125.223.14

# Ou ajoutez-la manuellement aux authorized_keys du serveur :
# cat ~/.ssh/deploy_key.pub | ssh ubuntu@135.125.223.14 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Affichez la clé PRIVÉE pour la copier dans GitHub Secrets
cat ~/.ssh/deploy_key
```

**Format pour `DEPLOY_SSH_PRIVATE_KEY` :**
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
...
(contenu complet de la clé privée)
...
-----END OPENSSH PRIVATE KEY-----
```


---

## Bonnes Pratiques de Sécurité

1. **Ne jamais commiter de secrets dans git**
   - Utilisez `.gitignore` pour exclure les fichiers sensibles
   - Utilisez GitHub Secrets pour toutes les informations d'identification

2. **Utilisez le principe du moindre privilège**
   - Créez un utilisateur dédié au déploiement avec des permissions minimales
   - Utilisez des clés SSH plutôt que des mots de passe
   - Effectuez une rotation régulière des secrets

3. **Surveillez les accès**
   - Consultez régulièrement les logs GitHub Actions
   - Configurez des alertes pour les déploiements échoués
   - Surveillez les logs d'accès du serveur

4. **Sécurité réseau**
   - Utilisez des règles de pare-feu pour restreindre les accès
   - Envisagez d'utiliser un VPN ou un tunnel SSH
   - Maintenez le serveur et Docker à jour

---

## Liste de Vérification

Avant d'exécuter le pipeline, vérifiez :

- [ ] `DOCKERHUB_USERNAME` est défini
- [ ] `DOCKERHUB_TOKEN` est défini et valide
- [ ] `DEPLOY_SERVER` est défini sur `135.125.223.14`
- [ ] `DEPLOY_SSH_USER` est défini
- [ ] `DEPLOY_SSH_PRIVATE_KEY` est défini avec la clé privée complète
- [ ] `DEPLOY_APPLI_PORT` est défini (ex: `8080`)
- [ ] `DEPLOY_APPLI_NAME` est défini (ex: `demo-boost-startup-java`)
- [ ] `MONGODB_COLLECTION_NAME` est défini (optionnel, par défaut `persons`)
- [ ] La connexion SSH fonctionne : `ssh ubuntu@135.125.223.14`


