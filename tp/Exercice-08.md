# Exercice 8 : Ajouter les Tests DAST

[⬅️ Exercice précédent](Exercice-07.md) | [🏠 Sommaire](README.md) | [Exercice suivant ➡️](Exercice-09.md)

---

## 🎯 Objectif

Tester l'application en cours d'exécution avec OWASP ZAP pour détecter les vulnérabilités runtime (DAST).

## ⏱️ Durée Estimée

45 minutes

---

## 📝 Instructions

### Étape 8.1 : Créer la configuration ZAP

Créez le fichier `.zap/rules.tsv` :

```tsv
10003	IGNORE	(Vulnerable JS Library)
10015	IGNORE	(Re-examine Cache-control Directives)
10027	IGNORE	(Information Disclosure - Suspicious Comments)
10096	IGNORE	(Timestamp Disclosure)
10109	IGNORE	(Modern Web Application)
```

### Étape 8.2 : Créer le workflow DAST

Créez `.github/workflows/dast-dynamic-security-testing.yml` :

```yaml
name: DAST - Dynamic Security Testing

on:
  workflow_call:

env:
  DOCKER_IMAGE_NAME: demo-boost-startup-java

jobs:
  dast-dynamic-security-testing:
    name: DAST - OWASP ZAP
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 📥 Download Docker image
        uses: actions/download-artifact@v4
        with:
          name: docker-image
          path: /tmp

      - name: 🐳 Load and start application
        run: |
          docker load -i /tmp/docker-image.tar
          docker run -d --name test-app -p 8080:8080 ${{ env.DOCKER_IMAGE_NAME }}:latest

          echo "⏳ Waiting for application to start..."
          for i in {1..30}; do
            if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
              echo "✅ Application is ready!"
              break
            fi
            echo "Attempt $i/30..."
            sleep 2
          done

      - name: 🎯 Run OWASP ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.12.0
        with:
          target: 'http://localhost:8080'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'

      - name: 📤 Upload ZAP Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: zap-report
          path: report_html.html
          retention-days: 30

      - name: 🧹 Cleanup
        if: always()
        run: |
          docker stop test-app || true
          docker rm test-app || true
```

### Étape 8.3 : Ajouter au pipeline principal

**Important** : DAST ne s'exécute PAS sur les Pull Requests (trop long).

Modifiez `main-pipeline.yml` :

```yaml
  build-and-scan-docker:
    needs:
      - code-quality-sast
      - secret-scanning
      - sca-dependency-scan
      - secure-iac-dockerfile-scan
    uses: ./.github/workflows/build-docker-image.yml

  # ═══════════════════════════════════════════════
  # ÉTAPE 7 : DAST (Pas sur les PRs)
  # ═══════════════════════════════════════════════
  dast-dynamic-security-testing:
    needs: build-and-scan-docker
    if: github.event_name != 'pull_request'  # ⚠️ Désactivé sur les PRs
    uses: ./.github/workflows/dast-dynamic-security-testing.yml
```

### Étape 8.4 : Tester

```bash
git add .
git commit -m "feat: add DAST security testing with OWASP ZAP"
git push origin main
```

**Note** : Si vous poussez vers une PR, DAST sera skippé !

---

## ✅ Critères de Validation

- [ ] L'application démarre dans Docker
- [ ] Le health check réussit (`/actuator/health`)
- [ ] ZAP scanne l'application
- [ ] Le rapport HTML est généré et uploadé
- [ ] Le conteneur est correctement nettoyé (`if: always()`)
- [ ] **Ne s'exécute PAS** sur les Pull Requests
- [ ] Le temps d'exécution est d'environ 5-10 minutes

---

## 🤔 Questions de Compréhension

1. **Pourquoi désactiver DAST sur les PRs ?**
   <details>
   <summary>Voir la réponse</summary>

   Plusieurs raisons :
   - **Temps** : DAST prend 5-10 minutes, ralentit les PRs
   - **Coût** : Utilise plus de minutes GitHub Actions
   - **Pertinence** : Les PRs testent le code, pas le déploiement
   - **Feedback** : SAST + SCA suffisent pour valider le code

   DAST est réservé :
   - Push vers main (avant déploiement)
   - Scheduled runs (monitoring hebdomadaire)
   </details>

2. **Différence entre SAST et DAST ?**
   <details>
   <summary>Voir la réponse</summary>

   | Aspect | SAST | DAST |
   |--------|------|------|
   | **Quand** | Pendant le développement | Application en cours d'exécution |
   | **Analyse** | Code source statique | Comportement runtime |
   | **Détecte** | Bugs de code, mauvaises pratiques | Vulnérabilités exploitables |
   | **Faux positifs** | Plus élevés | Plus faibles |
   | **Exemples** | Injection SQL dans le code | Faille XSS exploitable |
   | **Outils** | Semgrep, CodeQL | OWASP ZAP, Burp |

   **Les deux sont complémentaires !**
   </details>

3. **Pourquoi attendre le health check ?**
   <details>
   <summary>Voir la réponse</summary>

   - L'application Spring Boot met 10-30 secondes à démarrer
   - Si on scanne trop tôt, l'application ne répond pas
   - ZAP échouerait car le target est inaccessible

   La boucle `for i in {1..30}` :
   - Essaie jusqu'à 30 fois
   - Attend 2 secondes entre chaque tentative
   - Timeout total : 60 secondes max
   </details>

4. **Que teste OWASP ZAP exactement ?**
   <details>
   <summary>Voir la réponse</summary>

   ZAP Baseline Scan teste :
   - **XSS** : Injection de scripts
   - **Injection SQL** : Tentatives d'injection
   - **CSRF** : Cross-Site Request Forgery
   - **Headers de sécurité** : CSP, X-Frame-Options, etc.
   - **Cookies non sécurisés** : Pas de Secure/HttpOnly flags
   - **Redirections ouvertes**
   - **Exposition d'informations sensibles**

   C'est un scan passif + quelques tests actifs de base.
   </details>

---

## 🎯 Architecture Actuelle

```
build-and-test
    ├── [scans de sécurité en parallèle]
    └── build-and-scan-docker
            └── dast-dynamic-security-testing (si pas PR)
```

DAST est conditionnel : il s'exécute seulement sur les push vers main.

---

## 💡 Points Importants

### Conditions d'Exécution

```yaml
if: github.event_name != 'pull_request'
```

Autres conditions utiles :
```yaml
if: github.ref == 'refs/heads/main'  # Seulement sur main
if: github.event_name == 'schedule'  # Seulement sur schedule
if: always()  # Toujours, même si échec précédent
```

### Nettoyage avec `if: always()`

```yaml
- name: 🧹 Cleanup
  if: always()  # S'exécute même si le scan échoue
  run: docker stop test-app || true
```

Important pour :
- Libérer les ressources
- Éviter les conflits de ports
- Ne pas laisser de conteneurs orphelins

---

## 📚 Ressources

- [OWASP ZAP](https://www.zaproxy.org/)
- [ZAP Baseline Scan](https://www.zaproxy.org/docs/docker/baseline-scan/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [GitHub Actions Conditions](https://docs.github.com/en/actions/learn-github-actions/expressions)

---

## 🎉 Félicitations !

Votre application est maintenant testée en conditions réelles ! Dans l'exercice suivant, vous allez publier l'image Docker sur Docker Hub.

[Exercice suivant : Publication Docker Hub ➡️](Exercice-09.md)
