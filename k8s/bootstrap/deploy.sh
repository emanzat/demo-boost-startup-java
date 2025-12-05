#!/bin/bash

################################################################################
# Script d'installation complète : k3s + Traefik + cert-manager + ArgoCD
################################################################################
#
# Ce script installe et configure automatiquement :
#   1. k3s (Kubernetes léger avec Traefik inclus)
#   2. cert-manager (gestion des certificats SSL)
#   3. ClusterIssuers Let's Encrypt (staging et production)
#   4. ArgoCD (plateforme GitOps)
#   5. Ingress ArgoCD avec certificat SSL Let's Encrypt
#
# Usage: sudo ./deploy-all.sh
#
################################################################################

set -e  # Arrêter le script en cas d'erreur

################################################################################
# CONFIGURATION - Modifiez ces valeurs selon vos besoins
################################################################################

EMAIL="xxxx@gmail.com"              # Email pour Let's Encrypt
DOMAIN="argocd.xxxx.io"           # Domaine pour ArgoCD
CERT_MANAGER_VERSION="v1.14.1"         # Version de cert-manager
ARGOCD_VERSION="v2.9.3"                # Version d'ArgoCD
LETSENCRYPT_ISSUER="letsencrypt-prod"  # ou "letsencrypt-staging" pour les tests

################################################################################
# ÉTAPE 1 : Installation de k3s
################################################################################

echo "=========================================="
echo "ÉTAPE 1/6 : Installation de k3s"
echo "=========================================="
echo ""

# k3s est une distribution Kubernetes légère qui inclut Traefik par défaut
# Traefik sert d'ingress controller pour router le trafic HTTP/HTTPS
echo "📦 Téléchargement et installation de k3s..."
curl -sfL https://get.k3s.io | sh -

# Attendre que k3s démarre complètement
echo "⏳ Attente du démarrage de k3s (10 secondes)..."
sleep 10

################################################################################
# ÉTAPE 2 : Configuration de kubectl
################################################################################

echo ""
echo "=========================================="
echo "ÉTAPE 2/6 : Configuration de kubectl"
echo "=========================================="
echo ""

# Copier la configuration k3s pour l'utilisateur courant
# Cela permet d'utiliser kubectl sans sudo
echo "🔧 Configuration de kubectl pour l'utilisateur courant..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config

# Vérifier que le cluster fonctionne
echo "✅ Vérification du cluster k3s..."
kubectl get nodes

################################################################################
# ÉTAPE 3 : Installation de cert-manager
################################################################################

echo ""
echo "=========================================="
echo "ÉTAPE 3/6 : Installation de cert-manager"
echo "=========================================="
echo ""

# cert-manager gère automatiquement les certificats SSL
# Il crée et renouvelle les certificats Let's Encrypt
echo "📦 Installation de cert-manager ${CERT_MANAGER_VERSION}..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml

# Attendre que tous les pods cert-manager soient prêts
echo "⏳ Attente du démarrage de cert-manager (jusqu'à 5 minutes)..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/instance=cert-manager \
  -n cert-manager \
  --timeout=300s

################################################################################
# ÉTAPE 4 : Configuration des ClusterIssuers Let's Encrypt
################################################################################

echo ""
echo "=========================================="
echo "ÉTAPE 4/6 : Configuration Let's Encrypt"
echo "=========================================="
echo ""

# ClusterIssuer PRODUCTION
# Utilise l'API de production Let's Encrypt
# Les certificats sont reconnus par tous les navigateurs
echo "🔐 Configuration de Let's Encrypt PRODUCTION..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # Serveur ACME de production Let's Encrypt
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email pour les notifications d'expiration
    email: ${EMAIL}
    # Secret pour stocker la clé privée du compte ACME
    privateKeySecretRef:
      name: letsencrypt-prod
    # Résolveur HTTP-01 : vérifie la propriété du domaine via HTTP
    solvers:
    - http01:
        ingress:
          class: traefik
EOF

# ClusterIssuer STAGING
# Utilise l'API de staging Let's Encrypt pour les tests
# Pas de limite de rate-limiting, mais certificat non reconnu par les navigateurs
echo "🔐 Configuration de Let's Encrypt STAGING (pour tests)..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # Serveur ACME de staging Let's Encrypt
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: ${EMAIL}
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: traefik
EOF

################################################################################
# ÉTAPE 5 : Installation d'ArgoCD
################################################################################

echo ""
echo "=========================================="
echo "ÉTAPE 5/6 : Installation d'ArgoCD"
echo "=========================================="
echo ""

# ArgoCD est une plateforme GitOps pour Kubernetes
# Il synchronise automatiquement les applications depuis Git
echo "📦 Création du namespace ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "📦 Installation d'ArgoCD ${ARGOCD_VERSION}..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml

# Attendre que le serveur ArgoCD soit prêt
echo "⏳ Attente du démarrage d'ArgoCD (jusqu'à 5 minutes)..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd \
  --timeout=300s

# Configuration d'ArgoCD en mode "insecure"
# Cela désactive le TLS interne d'ArgoCD car Traefik gère déjà le TLS
echo "🔧 Configuration d'ArgoCD en mode insecure (TLS géré par Traefik)..."
kubectl patch configmap argocd-cmd-params-cm -n argocd \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'

# Redémarrer ArgoCD pour appliquer la configuration
echo "🔄 Redémarrage d'ArgoCD..."
kubectl rollout restart deployment argocd-server -n argocd

# Attendre que le nouveau pod soit prêt
echo "⏳ Attente du redémarrage d'ArgoCD..."
sleep 5
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd \
  --timeout=120s

################################################################################
# ÉTAPE 6 : Configuration de l'Ingress ArgoCD
################################################################################

echo ""
echo "=========================================="
echo "ÉTAPE 6/6 : Configuration de l'Ingress"
echo "=========================================="
echo ""

# Créer un Middleware Traefik pour rediriger HTTP vers HTTPS
echo "🔧 Création du middleware de redirection HTTPS..."
cat <<EOF | kubectl apply -f -
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: https-redirect
  namespace: argocd
spec:
  redirectScheme:
    scheme: https
    permanent: true
EOF

# Créer l'Ingress pour ArgoCD
# L'Ingress route le trafic HTTPS vers ArgoCD et demande un certificat SSL
echo "📦 Création de l'Ingress ArgoCD avec SSL..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    # Demander un certificat Let's Encrypt
    cert-manager.io/cluster-issuer: ${LETSENCRYPT_ISSUER}
    # Accepter le trafic HTTP et HTTPS
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
    # Activer TLS
    traefik.ingress.kubernetes.io/router.tls: "true"
    # Appliquer le middleware de redirection HTTPS
    traefik.ingress.kubernetes.io/router.middlewares: argocd-https-redirect@kubernetescrd
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - ${DOMAIN}
    # Secret où sera stocké le certificat SSL
    secretName: argocd-server-tls
  rules:
  - host: ${DOMAIN}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              name: http
EOF

# Attendre quelques secondes que l'ingress soit créé
echo "⏳ Attente de la création de l'Ingress..."
sleep 5

################################################################################
# RÉCUPÉRATION DU MOT DE PASSE ARGOCD
################################################################################

echo ""
echo "🔑 Récupération du mot de passe admin ArgoCD..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)

################################################################################
# AFFICHAGE DU RÉSUMÉ
################################################################################

echo ""
echo "=========================================="
echo "✅ INSTALLATION TERMINÉE !"
echo "=========================================="
echo ""
echo "📋 RÉCAPITULATIF DE L'INSTALLATION"
echo "=========================================="
echo ""
echo "🔧 Composants installés :"
echo "  ✅ k3s $(kubectl version --short 2>/dev/null | grep Server | awk '{print $3}')"
echo "  ✅ Traefik (inclus avec k3s)"
echo "  ✅ cert-manager ${CERT_MANAGER_VERSION}"
echo "  ✅ ArgoCD ${ARGOCD_VERSION}"
echo ""
echo "🔐 Let's Encrypt :"
echo "  ✅ ClusterIssuer 'letsencrypt-prod' (production)"
echo "  ✅ ClusterIssuer 'letsencrypt-staging' (tests)"
echo "  ✅ Email configuré : ${EMAIL}"
echo "  ✅ Issuer utilisé : ${LETSENCRYPT_ISSUER}"
echo ""
echo "🌐 Accès ArgoCD :"
echo "  URL      : https://${DOMAIN}"
echo "  Username : admin"
echo "  Password : ${ARGOCD_PASSWORD}"
echo ""
echo "📝 VÉRIFICATIONS IMPORTANTES"
echo "=========================================="
echo ""
echo "1. Vérifier que le DNS pointe vers ce serveur :"
echo "   dig +short ${DOMAIN}"
echo ""
echo "2. Vérifier l'état du certificat SSL (peut prendre 2-3 minutes) :"
echo "   kubectl get certificate -n argocd"
echo "   kubectl describe certificate argocd-server-tls -n argocd"
echo ""
echo "3. Vérifier l'ingress :"
echo "   kubectl get ingress -n argocd"
echo ""
echo "4. Tester l'accès HTTPS :"
echo "   curl -I https://${DOMAIN}"
echo ""
echo "📚 COMMANDES UTILES"
echo "=========================================="
echo ""
echo "# Voir tous les pods"
echo "kubectl get pods -A"
echo ""
echo "# Voir les logs ArgoCD"
echo "kubectl logs -n argocd deployment/argocd-server -f"
echo ""
echo "# Voir les logs cert-manager"
echo "kubectl logs -n cert-manager deployment/cert-manager -f"
echo ""
echo "# Récupérer le mot de passe admin"
echo "kubectl -n argocd get secret argocd-initial-admin-secret \\"
echo "  -o jsonpath=\"{.data.password}\" | base64 -d && echo"
echo ""
echo "# Changer l'issuer (staging <-> prod)"
echo "kubectl patch ingress argocd-server-ingress -n argocd --type='json' \\"
echo "  -p='[{\"op\": \"replace\", \"path\": \"/metadata/annotations/cert-manager.io~1cluster-issuer\", \"value\": \"letsencrypt-prod\"}]'"
echo "kubectl delete certificate argocd-server-tls -n argocd"
echo ""
echo "🎉 PROCHAINES ÉTAPES"
echo "=========================================="
echo ""
echo "1. Connectez-vous à ArgoCD : https://${DOMAIN}"
echo "2. Changez le mot de passe admin (recommandé)"
echo "3. Configurez vos repositories Git"
echo "4. Déployez vos applications !"
echo ""
echo "📖 Documentation :"
echo "  - ArgoCD : https://argo-cd.readthedocs.io/"
echo "  - cert-manager : https://cert-manager.io/docs/"
echo "  - k3s : https://docs.k3s.io/"
echo ""
