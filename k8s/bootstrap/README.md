# Installation k3s + ArgoCD avec Traefik et Let's Encrypt

Documentation complète pour l'installation et la gestion d'un cluster k3s avec ArgoCD, cert-manager et certificats SSL Let's Encrypt.

## 🚀 Installation rapide

### Installation complète en une seule commande

```bash
sudo ./deploy-all.sh
```

C'est tout ! Le script installe automatiquement :
- ✅ k3s (Kubernetes léger)
- ✅ Traefik (Ingress controller, inclus avec k3s)
- ✅ cert-manager (gestion des certificats SSL)
- ✅ ClusterIssuers Let's Encrypt (staging et production)
- ✅ ArgoCD (plateforme GitOps)
- ✅ Ingress ArgoCD avec certificat SSL
- ✅ Middleware de redirection HTTPS

**Temps d'installation :** ~2-3 minutes

### Configuration

Avant de lancer le script, vous pouvez modifier les variables de configuration en haut du fichier `deploy-all.sh` :

```bash
EMAIL="xxxx@gmail.com"              # Email pour Let's Encrypt
DOMAIN="argocd.xxxx.io"           # Domaine pour ArgoCD
CERT_MANAGER_VERSION="v1.14.1"         # Version de cert-manager
ARGOCD_VERSION="v2.9.3"                # Version d'ArgoCD
LETSENCRYPT_ISSUER="letsencrypt-prod"  # ou "letsencrypt-staging" pour tests
```

### Prérequis

1. **Serveur Linux** (Ubuntu/Debian recommandé)
2. **Accès root** (via sudo)
3. **DNS configuré** : Votre domaine doit pointer vers l'IP du serveur
4. **Ports ouverts** : 80 (HTTP) et 443 (HTTPS)

## 🔐 Accès à ArgoCD

### Connexion web

Après l'installation, le script affiche :
- L'URL d'accès : `https://votre-domaine.com`
- Le nom d'utilisateur : `admin`
- Le mot de passe initial

### Récupérer le mot de passe manuellement

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

### Changer le mot de passe (recommandé)

#### Via l'interface web
1. Connectez-vous à ArgoCD
2. Cliquez sur "User Info" (icône utilisateur en haut à droite)
3. Cliquez sur "Update Password"

#### Via ArgoCD CLI

```bash
# 1. Installer ArgoCD CLI
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

# 2. Se connecter
argocd login votre-domaine.com

# 3. Changer le mot de passe
argocd account update-password
```

## ✅ Vérifications

### Vérifier tous les composants

```bash
# Tous les pods
kubectl get pods -A

# Pods ArgoCD (doivent être en Running)
kubectl get pods -n argocd

# Pods cert-manager (doivent être en Running)
kubectl get pods -n cert-manager

# Traefik
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
```

### Vérifier le certificat SSL

```bash
# État du certificat (doit être Ready: True)
kubectl get certificate -n argocd

# Détails du certificat
kubectl describe certificate argocd-server-tls -n argocd

# Vérifier l'émetteur et la validité
openssl s_client -connect votre-domaine.com:443 -servername votre-domaine.com \
  </dev/null 2>/dev/null | openssl x509 -noout -issuer -subject -dates
```

### Vérifier l'ingress

```bash
# État de l'ingress
kubectl get ingress -n argocd

# Détails de l'ingress
kubectl describe ingress argocd-server-ingress -n argocd
```

### Tester l'accès HTTPS

```bash
# Test simple
curl -I https://votre-domaine.com

# Test avec vérification SSL
curl -v https://votre-domaine.com 2>&1 | grep -E "(SSL|certificate)"
```

## 🔧 Commandes utiles

### Gestion des pods

```bash
# Redémarrer ArgoCD
kubectl rollout restart deployment argocd-server -n argocd

# Redémarrer Traefik
kubectl rollout restart deployment traefik -n kube-system

# Voir les logs ArgoCD
kubectl logs -n argocd deployment/argocd-server -f

# Voir les logs cert-manager
kubectl logs -n cert-manager deployment/cert-manager -f

# Voir les logs Traefik
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik -f
```

### Gestion des certificats

```bash
# Forcer le renouvellement d'un certificat
kubectl delete certificate argocd-server-tls -n argocd

# Passer de staging à production
kubectl patch ingress argocd-server-ingress -n argocd --type='json' \
  -p='[{"op": "replace", "path": "/metadata/annotations/cert-manager.io~1cluster-issuer", "value": "letsencrypt-prod"}]'
kubectl delete certificate argocd-server-tls -n argocd

# Passer de production à staging (pour tests)
kubectl patch ingress argocd-server-ingress -n argocd --type='json' \
  -p='[{"op": "replace", "path": "/metadata/annotations/cert-manager.io~1cluster-issuer", "value": "letsencrypt-staging"}]'
kubectl delete certificate argocd-server-tls -n argocd
```

## 🐛 Résolution des problèmes

### Le certificat ne se crée pas

**Symptôme** : Le certificat reste en état `Ready: False`

**Solutions** :

1. **Vérifier que le DNS pointe vers le serveur**
   ```bash
   dig +short votre-domaine.com
   # Doit afficher l'IP de votre serveur
   ```

2. **Vérifier les logs cert-manager**
   ```bash
   kubectl logs -n cert-manager deployment/cert-manager -f
   ```

3. **Vérifier les événements du certificat**
   ```bash
   kubectl describe certificate argocd-server-tls -n argocd
   kubectl describe certificaterequest -n argocd
   ```

4. **Vérifier que les ports 80 et 443 sont accessibles**
   ```bash
   # Depuis un autre serveur
   curl -I http://votre-domaine.com
   curl -I https://votre-domaine.com
   ```

### ArgoCD n'est pas accessible

**Symptôme** : Erreur de connexion ou timeout

**Solutions** :

1. **Vérifier que Traefik fonctionne**
   ```bash
   kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
   ```

2. **Vérifier que les pods ArgoCD sont en Running**
   ```bash
   kubectl get pods -n argocd
   ```

3. **Tester l'accès en local avec port-forward**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:80
   # Accédez à http://localhost:8080
   ```

4. **Vérifier les logs Traefik**
   ```bash
   kubectl logs -n kube-system -l app.kubernetes.io/name=traefik -f
   ```

### Erreur "too many redirects" ou boucle de redirection

**Symptôme** : Le navigateur affiche "ERR_TOO_MANY_REDIRECTS"

**Cause** : ArgoCD utilise son propre TLS au lieu du TLS de Traefik

**Solution** : Le script configure automatiquement ArgoCD en mode `insecure`. Si le problème persiste :

```bash
# Vérifier la configuration
kubectl get configmap argocd-cmd-params-cm -n argocd -o yaml | grep server.insecure

# Si absent ou = false, patcher :
kubectl patch configmap argocd-cmd-params-cm -n argocd \
  --type merge -p '{"data":{"server.insecure":"true"}}'

# Redémarrer ArgoCD
kubectl rollout restart deployment argocd-server -n argocd
```

### Certificat SSL non reconnu par le navigateur

**Symptôme** : "Votre connexion n'est pas privée"

**Causes possibles** :

1. **Utilisation de letsencrypt-staging**
    - Les certificats staging ne sont pas reconnus par les navigateurs
    - Solution : Passer à `letsencrypt-prod` (voir commandes ci-dessus)

2. **Cache SSL du navigateur**
    - Le navigateur a mis en cache un ancien certificat
    - Solution : Vider le cache SSL (Chrome : `chrome://net-internals/#hsts`)

3. **DNS incorrect**
    - Le domaine ne pointe pas vers le bon serveur
    - Solution : Vérifier avec `dig +short votre-domaine.com`

### Port-forward pour accès sans domaine

Si vous n'avez pas de domaine configuré :

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Puis accédez à : http://localhost:8080

## 📚 Utilisation d'ArgoCD

### Créer une application de test

```bash
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

### Connecter un repository Git privé

Via l'interface web :
1. Settings > Repositories
2. Connect Repo
3. Choisir HTTPS ou SSH
4. Entrer les credentials

Via CLI :
```bash
argocd repo add https://github.com/votre-org/votre-repo.git \
  --username votre-username \
  --password votre-token
```

## 🗑️ Désinstallation

### Désinstaller complètement k3s

```bash
/usr/local/bin/k3s-uninstall.sh
```

Cela supprime :
- k3s et tous ses composants
- Traefik
- cert-manager
- ArgoCD
- Tous les pods et configurations

### Nettoyer les fichiers de configuration

```bash
rm -rf ~/.kube
```

## 🔄 Mise à jour des composants

### Mettre à jour ArgoCD

```bash
# Modifier la version dans deploy-all.sh
# Puis réappliquer le manifest
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/vX.Y.Z/manifests/install.yaml
```

### Mettre à jour cert-manager

```bash
# Modifier la version dans deploy-all.sh
# Puis réappliquer le manifest
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/vX.Y.Z/cert-manager.yaml
```

## 📖 Ressources utiles

- [Documentation ArgoCD](https://argo-cd.readthedocs.io/)
- [ArgoCD avec Traefik](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#traefik-v22)
- [cert-manager](https://cert-manager.io/docs/)
- [k3s](https://docs.k3s.io/)
- [Let's Encrypt](https://letsencrypt.org/docs/)

## 💡 Conseils de production

1. **Changez le mot de passe admin** immédiatement après l'installation
2. **Utilisez letsencrypt-prod** pour la production (pas staging)
3. **Configurez des backups** réguliers d'ArgoCD
4. **Activez RBAC** pour gérer les accès utilisateurs
5. **Surveillez l'expiration** des certificats (renouvellement auto tous les 60 jours)
6. **Utilisez des secrets** Kubernetes pour les credentials Git
7. **Configurez des notifications** ArgoCD (Slack, email, etc.)

## 🎓 Architecture

```
Internet
    |
    | (HTTPS)
    v
Traefik (Ingress Controller)
    |
    | (HTTP)
    v
ArgoCD Server (mode insecure)
    |
    v
Applications Kubernetes
```

- **Traefik** : Gère le TLS/SSL et route le trafic
- **cert-manager** : Émet et renouvelle les certificats Let's Encrypt
- **ArgoCD** : Mode insecure (pas de TLS interne, Traefik s'en charge)
- **Middleware** : Redirige automatiquement HTTP vers HTTPS
