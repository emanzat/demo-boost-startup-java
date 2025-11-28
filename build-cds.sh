#!/bin/bash

# Script simplifié pour builder avec CDS (Class Data Sharing)
# Usage:
#   ./build-cds.sh true    # Avec Spring AOT activé
#   ./build-cds.sh false   # Avec Spring AOT désactivé (par défaut)
#   ./build-cds.sh         # Avec Spring AOT désactivé (par défaut)

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration par défaut
SPRING_AOT_ENABLED=${1:-false}
CDS_ARCHIVE_FILE="app-cds-$SPRING_AOT_ENABLED.jsa"
lsof -ti:8080 | xargs kill -9 2>/dev/null || true

# Valider l'argument
if [ "$SPRING_AOT_ENABLED" != "true" ] && [ "$SPRING_AOT_ENABLED" != "false" ]; then
    echo -e "${RED}Argument invalide: $SPRING_AOT_ENABLED${NC}"
    echo "Usage: $0 [true|false]"
    echo "  true  - Active -Dspring.aot.enabled=true"
    echo "  false - Active -Dspring.aot.enabled=false (défaut)"
    exit 1
fi

# Afficher la configuration
echo -e "${GREEN}=== Build avec CDS (Class Data Sharing) ===${NC}"
echo -e "${YELLOW}spring.aot.enabled = $SPRING_AOT_ENABLED${NC}\n"

# Étape 1: Clean et build du projet
echo -e "${YELLOW}Étape 1: Clean et compilation du projet Maven${NC}"
if [ "$SPRING_AOT_ENABLED" = "true" ]; then
    mvn clean compile spring-boot:process-aot package -DskipTests=true
else
    mvn clean compile package -DskipTests=true
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}Erreur lors du build Maven${NC}"
    exit 1
fi

# Trouver le JAR généré
JAR_FILE=$(find target -name "*.jar" -type f | grep -v "original" | head -n 1)

if [ -z "$JAR_FILE" ]; then
    echo -e "${RED}Aucun fichier JAR trouvé dans target/${NC}"
    exit 1
fi

echo -e "${GREEN}JAR trouvé: $JAR_FILE${NC}\n"

# Étape 2: Extraire le JAR
echo -e "${YELLOW}Étape 2: Extraction du JAR${NC}"
EXTRACTED_DIR="target/extracted"
rm -rf "$EXTRACTED_DIR"
mkdir -p "$EXTRACTED_DIR"

java -Djarmode=tools -jar "$JAR_FILE" extract --destination "$EXTRACTED_DIR"

if [ $? -ne 0 ]; then
    echo -e "${RED}Erreur lors de l'extraction du JAR${NC}"
    exit 1
fi

echo -e "${GREEN}JAR extrait dans: $EXTRACTED_DIR${NC}\n"

# Étape 3: Générer l'archive CDS
echo -e "${YELLOW}Étape 3: Génération de l'archive CDS${NC}"
EXTRACTED_JAR="$EXTRACTED_DIR/$(basename $JAR_FILE)"

# Copier le JAR extrait si nécessaire
if [ ! -f "$EXTRACTED_JAR" ]; then
    cp "$JAR_FILE" "$EXTRACTED_JAR"
fi

# Générer l'archive CDS
echo -e "${GREEN}Génération de l'archive CDS avec -Dspring.aot.enabled=$SPRING_AOT_ENABLED${NC}"
java -Dspring.aot.enabled=$SPRING_AOT_ENABLED -Dspring.context.exit=onRefresh -XX:ArchiveClassesAtExit="$CDS_ARCHIVE_FILE" -jar "$EXTRACTED_JAR"

if [ $? -ne 0 ]; then
    echo -e "${RED}Erreur lors de la génération de l'archive CDS${NC}"
    exit 1
fi

echo -e "${GREEN}Archive CDS générée: $CDS_ARCHIVE_FILE${NC}\n"

# Étape 4: Exécuter avec l'archive CDS
echo -e "${YELLOW}Étape 4: Exécution avec l'archive CDS${NC}"
echo -e "${GREEN}Pour exécuter l'application, utilisez:${NC}"
echo -e "java -Dspring.aot.enabled=$SPRING_AOT_ENABLED -XX:SharedArchiveFile=$CDS_ARCHIVE_FILE -jar $EXTRACTED_JAR"

echo ""
echo -e "${YELLOW}Voulez-vous lancer l'application maintenant? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Lancement de l'application avec l'archive CDS...${NC}\n"

    # Capturer les logs dans un fichier temporaire
    LOG_FILE=$(mktemp)

    # Lancer l'application
    java -Dspring.aot.enabled=$SPRING_AOT_ENABLED -XX:SharedArchiveFile="$CDS_ARCHIVE_FILE" -jar "$EXTRACTED_JAR" 2>&1 | tee "$LOG_FILE" &

    APP_PID=$!

    # Attendre que l'application démarre (détection du message "Started")
    timeout=60
    elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if grep -q "Started.*in" "$LOG_FILE"; then
            # Extraire le temps de démarrage
            STARTUP_TIME=$(grep "Started.*in" "$LOG_FILE" | sed -n 's/.*Started.*in \([0-9.]*\) seconds.*/\1/p' | tail -1)
            echo ""
            echo -e "${GREEN}======================================${NC}"
            echo -e "${GREEN}Temps de démarrage: ${YELLOW}${STARTUP_TIME} secondes${NC}"
            echo -e "${GREEN}======================================${NC}"
            break
        fi
        sleep 0.5
        elapsed=$((elapsed + 1))
    done

    # Nettoyer le fichier temporaire
    rm -f "$LOG_FILE"

    # Attendre la fin du processus
    wait $APP_PID
else
    echo -e "${GREEN}Script terminé avec succès!${NC}"
    echo -e "Archive CDS disponible: ${YELLOW}$CDS_ARCHIVE_FILE${NC}"
    echo -e "JAR extrait: ${YELLOW}$EXTRACTED_JAR${NC}"
    echo -e "Mode: ${YELLOW}spring.aot.enabled=$SPRING_AOT_ENABLED${NC}"
fi