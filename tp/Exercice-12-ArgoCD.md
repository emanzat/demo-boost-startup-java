# Exercice 12 : Déploiement GitOps avec ArgoCD

[⬅️ Exercice précédent](Exercice-11.md) | [🏠 Sommaire](README.md)

---

## 🎯 Objectif

Déployer automatiquement votre application Java sur Kubernetes avec ArgoCD en suivant les principes GitOps.

## ⏱️ Durée Estimée

45 minutes

---

## ⚠️ IMPORTANT : Configuration Personnalisée

**Chaque étudiant a son propre environnement isolé.**

### 🔢 Votre numéro d'étudiant

Au début de la session, vous avez reçu un **numéro d'étudiant** de 1 à 10.

**Exemple** : Si vous êtes l'étudiant n°3, votre numéro est `3`.

### 📝 Configuration à personnaliser

Avant de commencer, vous devez modifier **2 fichiers** avec votre numéro :

#### 1. Namespace Kubernetes : `k8s/appli/appli.yaml`

**Remplacez** :
```yaml
kind: Namespace
metadata:
  name: cesi1    # ← CHANGEZ ICI
```

**Par** (si vous êtes étudiant n°3) :
```yaml
kind: Namespace
metadata:
  name: cesi3    # ← Votre numéro
```

**Changez aussi dans** :
- `metadata.namespace` du Deployment
- `metadata.namespace` du Service
- `metadata.namespace` de l'Ingress

#### 2. Domaine Ingress : `k8s/appli/appli.yaml`

**Remplacez** :
```yaml
spec:
  rules:
    - host: cesi1.beincloud.io    # ← CHANGEZ ICI
```

**Par** (si vous êtes étudiant n°3) :
```yaml
spec:
  rules:
    - host: cesi3.beincloud.io    # ← Votre numéro
```

#### 3. Application ArgoCD : `k8s/argocd-crds/ema-demo-java-application.yaml`

**Remplacez** :
```yaml
metadata:
  name: ema-demo-java    # ← CHANGEZ ICI
```

**Par** (si vous êtes étudiant n°3) :
```yaml
metadata:
  name: ema-demo-java-cesi3    # ← Votre numéro
```

**Et aussi** :
```yaml
destination:
  namespace: cesi1    # ← CHANGEZ ICI
```

**Par** :
```yaml
destination:
  namespace: cesi3    # ← Votre numéro
```

### 🚀 Script de remplacement automatique

Pour faciliter, utilisez ce script :

```bash
# Remplacez X par votre numéro (exemple: 3)
STUDENT_NUMBER=X

# Backup des fichiers originaux
cp k8s/appli/appli.yaml k8s/appli/appli.yaml.bak
cp k8s/argocd-crds/ema-demo-java-application.yaml k8s/argocd-crds/ema-demo-java-application.yaml.bak

# Remplacement dans appli.yaml
sed -i.tmp "s/cesi1/cesi${STUDENT_NUMBER}/g" k8s/appli/appli.yaml
rm k8s/appli/appli.yaml.tmp

# Remplacement dans l'application ArgoCD
sed -i.tmp "s/ema-demo-java/ema-demo-java-cesi${STUDENT_NUMBER}/g" k8s/argocd-crds/ema-demo-java-application.yaml
sed -i.tmp "s/namespace: cesi1/namespace: cesi${STUDENT_NUMBER}/g" k8s/argocd-crds/ema-demo-java-application.yaml
rm k8s/argocd-crds/ema-demo-java-application.yaml.tmp

# Vérification
echo "=== Vérification de la configuration ==="
echo "Namespace dans appli.yaml:"
grep "name: cesi" k8s/appli/appli.yaml | head -1
echo ""
echo "Domaine Ingress:"
grep "host: cesi" k8s/appli/appli.yaml
echo ""
echo "Application ArgoCD:"
grep "name: ema-demo-java" k8s/argocd-crds/ema-demo-java-application.yaml
echo "Namespace destination:"
grep "namespace: cesi" k8s/argocd-crds/ema-demo-java-application.yaml

# Commit des changements
git add k8s/appli/appli.yaml k8s/argocd-crds/ema-demo-java-application.yaml
git commit -m "config: personnalisation pour étudiant ${STUDENT_NUMBER}"
git push origin main
```

### ✅ Vérification

Après avoir exécuté le script, vérifiez que :

- [ ] **Namespace** : `cesiX` (où X = votre numéro)
- [ ] **Domaine** : `cesiX.beincloud.io`
- [ ] **Application ArgoCD** : `ema-demo-java-cesiX`

**Exemple pour étudiant n°3** :
- Namespace : `cesi3`
- Domaine : `cesi3.beincloud.io`
- App ArgoCD : `ema-demo-java-cesi3`

### 📋 Tableau de correspondance

| Étudiant | Namespace | Domaine | App ArgoCD |
|----------|-----------|---------|------------|
| 1 | `cesi1` | `cesi1.beincloud.io` | `ema-demo-java-cesi1` |
| 2 | `cesi2` | `cesi2.beincloud.io` | `ema-demo-java-cesi2` |
| 3 | `cesi3` | `cesi3.beincloud.io` | `ema-demo-java-cesi3` |
| 4 | `cesi4` | `cesi4.beincloud.io` | `ema-demo-java-cesi4` |
| 5 | `cesi5` | `cesi5.beincloud.io` | `ema-demo-java-cesi5` |
| 6 | `cesi6` | `cesi6.beincloud.io` | `ema-demo-java-cesi6` |
| 7 | `cesi7` | `cesi7.beincloud.io` | `ema-demo-java-cesi7` |
| 8 | `cesi8` | `cesi8.beincloud.io` | `ema-demo-java-cesi8` |
| 9 | `cesi9` | `cesi9.beincloud.io` | `ema-demo-java-cesi9` |
| 10 | `cesi10` | `cesi10.beincloud.io` | `ema-demo-java-cesi10` |

---

## 📚 Qu'est-ce qu'ArgoCD ?

**ArgoCD** est un outil de déploiement continu pour Kubernetes qui suit le principe **GitOps** :

- 📦 **Git comme source de vérité** : Tout l'état désiré est dans Git
- 🔄 **Synchronisation automatique** : ArgoCD surveille Git et applique les changements
- 🔍 **Visibilité** : Interface web pour voir l'état de vos déploiements
- 🔧 **Self-healing** : Répare automatiquement les modifications manuelles

### GitOps vs Traditional CI/CD

| Aspect | CI/CD Traditionnel | GitOps avec ArgoCD |
|--------|-------------------|-------------------|
| Déploiement | Pipeline push vers K8s | K8s pull depuis Git |
| Source de vérité | Scripts CI/CD | Manifestes Git |
| État désiré | Implicite | Déclaratif dans Git |
| Rollback | Re-run pipeline | Git revert |
| Drift detection | Manuelle | Automatique |

---

## 📝 Instructions

### Étape 12.1 : Connexion à ArgoCD

1. **Accédez à l'interface ArgoCD** :
   ```
   https://argocd.beincloud.io
   ```

2. **Connectez-vous** :
   - **Username** : `admin`
   - **Password** : `123456`

3. **Explorez l'interface** :
   - Cliquez sur "Applications" dans le menu
   - Vous devriez voir l'application `mongodb` déjà déployée

### Étape 12.2 : Créer l'application ArgoCD pour votre app Java

L'application ArgoCD a déjà été créée dans le fichier :
```
k8s/argocd-crds/ema-demo-java-application.yaml
```

**Examinez le fichier** :

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ema-demo-java
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/emanzat/demo-boost-startup-java.git
    targetRevision: HEAD
    path: k8s/appli
  destination:
    server: https://kubernetes.default.svc
    namespace: cesi1
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
```

**Points clés** :
- 📂 **path: k8s/appli** : ArgoCD va surveiller ce dossier
- 🎯 **namespace: cesi1** : Déploiement dans le namespace cesi1
- 🔄 **syncPolicy** : Seulement `CreateNamespace=true` (pas de sync auto pour l'instant)

### Étape 12.3 : Déployer l'application (CLI)

```bash
# Appliquer l'application ArgoCD
kubectl apply -f k8s/argocd-crds/ema-demo-java-application.yaml

# Vérifier que l'application est créée
kubectl get application -n argocd ema-demo-java
```

**Résultat attendu** :
```
NAME            SYNC STATUS   HEALTH STATUS
ema-demo-java   OutOfSync     Missing
```

### Étape 12.4 : Première synchronisation (MANUELLE via UI)

1. **Retournez sur ArgoCD UI** : https://argocd.beincloud.io

2. **Trouvez l'application `ema-demo-java`** :
   - Elle devrait apparaître avec le statut "OutOfSync"
   - Cliquez dessus pour voir les détails

3. **Analysez l'état** :
   - Vous verrez les ressources : Namespace, Deployment, Service, Ingress
   - Toutes sont "OutOfSync" car pas encore déployées

4. **Synchronisation manuelle** :
   - Cliquez sur le bouton **"SYNC"** en haut
   - Une fenêtre s'ouvre :
     - ✅ Cochez "SYNCHRONIZE"
     - Ne cochez PAS "PRUNE" ni "DRY RUN" pour l'instant
   - Cliquez sur **"SYNCHRONIZE"**

5. **Observez le déploiement** :
   - ArgoCD va créer toutes les ressources
   - Les statuts vont passer de "OutOfSync" → "Syncing" → "Synced"
   - Les pods vont démarrer (vous verrez les conteneurs)
   - Le health status va passer à "Healthy" (vert)

### Étape 12.5 : Vérifier le déploiement

```bash
# Vérifier les pods
kubectl get pods -n cesi1

# Vérifier le service
kubectl get svc -n cesi1

# Vérifier l'ingress
kubectl get ingress -n cesi1

# Tester l'application
curl http://cesi1.beincloud.io/actuator/health
```

**Résultat attendu** :
```json
{"status":"UP"}
```

### Étape 12.6 : Activer la synchronisation automatique (via UI)

1. **Dans ArgoCD UI, cliquez sur l'application `ema-demo-java`**

2. **Cliquez sur "APP DETAILS"** (en haut à gauche)

3. **Cliquez sur "EDIT"** en haut

4. **Modifiez la Sync Policy** :
   - Trouvez la section "SYNC POLICY"
   - Activez **"AUTOMATED"**
   - Cochez les options suivantes :
     - ✅ **PRUNE RESOURCES** : Supprime les ressources non présentes dans Git
     - ✅ **SELF HEAL** : Répare automatiquement si modifications manuelles
   - Cliquez sur **"SAVE"**

5. **Configuration de retry (optionnel)** :
   - Toujours dans "EDIT"
   - Trouvez "RETRY"
   - Activez et configurez :
     - Limit: `5`
     - Duration: `5s`
     - Max Duration: `3m`
     - Factor: `2`

6. **Sauvegardez** en cliquant sur "SAVE" en haut

### Étape 12.7 : Tester la synchronisation automatique

**Test 1 : Modification via Git** :

1. **Modifiez le nombre de replicas** dans `k8s/appli/appli.yaml` :
   ```yaml
   spec:
     replicas: 3  # Changez de 2 à 3
   ```

2. **Commit et push** :
   ```bash
   git add k8s/appli/appli.yaml
   git commit -m "test: increase replicas to 3"
   git push origin main
   ```

3. **Attendez ~3 minutes** (ou forcez la sync dans ArgoCD UI)

4. **Vérifiez** :
   ```bash
   kubectl get pods -n cesi1
   # Vous devriez voir 3 pods
   ```

**Test 2 : Self-healing** :

1. **Modifiez manuellement un pod** :
   ```bash
   # Supprimer un pod manuellement
   kubectl delete pod -n cesi1 -l app=ema-demo-java --force
   ```

2. **Observez ArgoCD** :
   - ArgoCD va détecter que l'état réel ≠ état désiré
   - Il va automatiquement recréer les pods pour avoir 3 replicas

3. **Vérifiez dans UI** :
   - Le statut restera "Healthy" et "Synced"
   - Les pods sont recréés automatiquement

### Étape 12.8 : Exporter la configuration finale

ArgoCD a modifié votre application. Exportez la configuration pour la sauvegarder dans Git :

```bash
# Exporter l'application ArgoCD
kubectl get application -n argocd ema-demo-java -o yaml > k8s/argocd-crds/ema-demo-java-application-final.yaml

# Ou utiliser ArgoCD CLI
argocd app get ema-demo-java -o yaml > k8s/argocd-crds/ema-demo-java-application-final.yaml
```

Ensuite, copiez la configuration complète dans le fichier original :

```bash
# Comparez les deux fichiers
diff k8s/argocd-crds/ema-demo-java-application.yaml k8s/argocd-crds/ema-demo-java-application-final.yaml
```

Mettez à jour `ema-demo-java-application.yaml` avec la sync policy complète :

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
    allowEmpty: false
  syncOptions:
    - CreateNamespace=true
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

---

## ✅ Critères de Validation

- [ ] Connexion réussie à ArgoCD UI (https://argocd.beincloud.io)
- [ ] Application `ema-demo-java` créée dans ArgoCD
- [ ] Première synchronisation manuelle effectuée
- [ ] Application déployée avec succès (status "Healthy" et "Synced")
- [ ] Synchronisation automatique activée (via UI)
- [ ] Test de modification Git → déploiement auto réussi
- [ ] Test de self-healing réussi (suppression pod → recréation auto)
- [ ] Configuration finale sauvegardée dans Git

---

## 🤔 Questions de Compréhension

1. **Qu'est-ce que le GitOps ?**
   <details>
   <summary>Voir la réponse</summary>

   GitOps est une pratique de gestion d'infrastructure où :
   - **Git est la source de vérité unique** : Tout l'état désiré est versionné dans Git
   - **Déploiements déclaratifs** : On déclare l'état désiré, pas les étapes
   - **Pull vs Push** : Le cluster Kubernetes pull depuis Git au lieu d'être pushé par CI/CD
   - **Convergence automatique** : L'état réel converge vers l'état désiré
   - **Auditabilité** : Tous les changements sont tracés dans Git

   **Avantages** :
   - Rollback facile (`git revert`)
   - Disaster recovery rapide (tout est dans Git)
   - Audit trail complet
   - Drift detection automatique
   </details>

2. **Quelle est la différence entre Sync Manual et Automated ?**
   <details>
   <summary>Voir la réponse</summary>

   **Sync Manual** :
   - ArgoCD détecte les changements dans Git
   - Affiche "OutOfSync" dans l'UI
   - Nécessite un clic sur "SYNC" pour déployer
   - Bon pour : environnements de production critiques, besoin d'approbation

   **Sync Automated** :
   - ArgoCD détecte ET applique automatiquement les changements
   - Synchronisation toutes les 3 minutes (par défaut)
   - Pas d'intervention humaine nécessaire
   - Bon pour : environnements de dev/staging, CI/CD complet

   **Best practice** : Manual pour PROD, Automated pour DEV/STAGING
   </details>

3. **Que fait `prune: true` ?**
   <details>
   <summary>Voir la réponse</summary>

   `prune: true` supprime les ressources qui ne sont **plus présentes dans Git**.

   **Exemple** :
   1. Vous avez un ConfigMap dans Git
   2. ArgoCD le déploie dans K8s
   3. Vous supprimez le ConfigMap de Git
   4. Avec `prune: true` → ArgoCD supprime le ConfigMap de K8s
   5. Avec `prune: false` → Le ConfigMap reste dans K8s (orphelin)

   **Important** : Activer `prune` seulement quand vous êtes sûr que Git est à jour !
   </details>

4. **Que fait `selfHeal: true` ?**
   <details>
   <summary>Voir la réponse</summary>

   `selfHeal: true` répare automatiquement les **modifications manuelles** sur le cluster.

   **Exemple** :
   1. Git dit : `replicas: 3`
   2. Quelqu'un fait `kubectl scale deployment --replicas=5`
   3. ArgoCD détecte le drift (3 ≠ 5)
   4. Avec `selfHeal: true` → ArgoCD remet à 3 automatiquement
   5. Avec `selfHeal: false` → ArgoCD affiche "OutOfSync" mais ne fait rien

   **Cas d'usage** :
   - Empêche les modifications manuelles non documentées
   - Force le passage par Git (discipline GitOps)
   - Protection contre les erreurs humaines
   </details>

5. **Comment fonctionne le retry avec backoff ?**
   <details>
   <summary>Voir la réponse</summary>

   Le retry avec backoff exponentiel réessaie les synchronisations échouées avec des délais croissants :

   ```yaml
   retry:
     limit: 5           # Maximum 5 tentatives
     backoff:
       duration: 5s     # Première tentative après 5s
       factor: 2        # Multiplier par 2 à chaque fois
       maxDuration: 3m  # Maximum 3 minutes entre tentatives
   ```

   **Séquence** :
   1. Échec → Attend 5s → Retry 1
   2. Échec → Attend 10s (5s × 2) → Retry 2
   3. Échec → Attend 20s (10s × 2) → Retry 3
   4. Échec → Attend 40s (20s × 2) → Retry 4
   5. Échec → Attend 80s, mais max 3m, donc attend 3m → Retry 5
   6. Si échec → Arrêt

   **Pourquoi** : Donne le temps aux dépendances de démarrer (ex: MongoDB doit être prêt avant l'app)
   </details>

6. **Pourquoi activer la sync auto via UI puis sauvegarder dans Git ?**
   <details>
   <summary>Voir la réponse</summary>

   **Approche pédagogique en 2 étapes** :

   **Étape 1 - Via UI** :
   - Permet de **tester** facilement les options
   - Voir **immédiatement** l'impact de chaque paramètre
   - **Apprendre** les différences entre prune/selfHeal/retry
   - Interface visuelle intuitive pour débutants

   **Étape 2 - Sauvegarder dans Git** :
   - **GitOps complet** : La config ArgoCD elle-même est dans Git
   - **Reproductible** : Facile de recréer l'app ArgoCD
   - **Disaster recovery** : Si ArgoCD est supprimé, on peut tout recréer
   - **Infrastructure as Code** : Tout est versionné

   **En production** : Vous créeriez directement le YAML complet dans Git sans passer par UI.
   </details>

---

## 🎯 Architecture GitOps Complète

```
┌─────────────────────────────────────────────────────────┐
│                     GitHub Repository                    │
│  https://github.com/emanzat/demo-boost-startup-java.git │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ Git Push (Developer)
                     │
┌────────────────────▼────────────────────────────────────┐
│                   GitHub Actions                         │
│  • Build & Test                                          │
│  • Security Scans (SAST, SCA, Secrets, DAST)            │
│  • Build Docker Image                                    │
│  • Push to Docker Hub                                    │
│  • Update k8s/appli/appli.yaml with new image tag       │
│  • Git Commit & Push                                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ Updated manifest in Git
                     │
┌────────────────────▼────────────────────────────────────┐
│                      ArgoCD                              │
│  • Polls Git every 3 minutes                             │
│  • Detects changes in k8s/appli/                         │
│  • Syncs to Kubernetes cluster                           │
│  • Self-heals if manual changes                          │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ kubectl apply
                     │
┌────────────────────▼────────────────────────────────────┐
│              Kubernetes Cluster (K3s)                    │
│  Namespace: cesi1                                        │
│  • Deployment (ema-demo-java) - 3 replicas               │
│  • Service (ClusterIP)                                   │
│  • Ingress (http://cesi1.beincloud.io)                   │
│                                                           │
│  Namespace: mongodb                                      │
│  • MongoDB StatefulSet/Deployment                        │
│  • PersistentVolumeClaim                                 │
│  • Service                                               │
└──────────────────────────────────────────────────────────┘
```

**Flux complet** :
1. Developer push code → GitHub
2. GitHub Actions build, scan, push image
3. GitHub Actions update manifest avec nouveau tag
4. ArgoCD détecte changement dans Git
5. ArgoCD applique changement dans K8s
6. K8s pull nouvelle image depuis Docker Hub
7. Application déployée automatiquement

**Aucune intervention manuelle après le push Git !** 🚀

---

## 💡 Points Importants

### Différence avec le déploiement SSH (Exercice 10)

| Aspect | Déploiement SSH (Ex 10) | GitOps ArgoCD (Ex 12) |
|--------|------------------------|----------------------|
| Méthode | GitHub Actions SSH vers serveur | ArgoCD pull depuis Git |
| État | Implicite (dans le script) | Déclaratif (manifeste YAML) |
| Drift | Non détecté | Détecté et réparé |
| Rollback | Re-run pipeline ou manuel | `git revert` |
| Visibilité | Logs CI/CD | UI ArgoCD + K8s |
| Multi-cluster | Difficile | Facile (1 ArgoCD, N clusters) |

### Pourquoi les deux approches ?

**Déploiement SSH** :
- ✅ Simple pour VM ou serveurs bare-metal
- ✅ Pas besoin de Kubernetes
- ❌ Pas de gestion d'état déclarative

**GitOps ArgoCD** :
- ✅ Gestion d'état déclarative
- ✅ Self-healing et drift detection
- ✅ Multi-cluster facilement
- ❌ Nécessite Kubernetes et ArgoCD

### Sync Policy : Quand utiliser quoi ?

```yaml
# Développement / Staging
syncPolicy:
  automated:
    prune: true      # ✅ Nettoie automatiquement
    selfHeal: true   # ✅ Répare automatiquement

# Production
syncPolicy:
  automated:
    prune: false     # ⚠️ Prudence avec la suppression
    selfHeal: true   # ✅ Répare quand même
  # Ou même : pas de automated (sync manuel uniquement)
```

### ArgoCD CLI vs UI

**UI** :
- Visuel et intuitif
- Bon pour l'apprentissage
- Parfait pour le troubleshooting

**CLI** :
- Automatisable
- Scriptable
- CI/CD pipelines

**Exemple CLI** :
```bash
# Installer ArgoCD CLI
brew install argocd

# Login
argocd login argocd.beincloud.io --username admin --password 123456

# Lister les apps
argocd app list

# Voir l'état
argocd app get ema-demo-java

# Forcer sync
argocd app sync ema-demo-java

# Voir les logs
argocd app logs ema-demo-java
```

---

## 📚 Ressources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [Kubernetes Patterns: GitOps](https://kubernetes.io/blog/2021/04/19/introducing-gitops/)

---

## 🎉 Félicitations !

Vous avez mis en place un pipeline GitOps complet avec ArgoCD ! Votre application est maintenant :

- ✅ **Déployée automatiquement** depuis Git
- ✅ **Auto-réparée** en cas de modification manuelle
- ✅ **Synchronisée** avec l'état désiré dans Git
- ✅ **Observable** via ArgoCD UI
- ✅ **Rollbackable** facilement via `git revert`

**Vous maîtrisez maintenant** :
- Les principes GitOps
- ArgoCD (UI et CLI)
- Déploiement déclaratif Kubernetes
- Sync policies (manual, automated, prune, selfHeal)
- Stratégies de retry

[🏠 Retour au sommaire](README.md)

---

**Version :** 1.0
**Dernière mise à jour :** 2025-12-05
**Auteur :** DevSecOps Team
