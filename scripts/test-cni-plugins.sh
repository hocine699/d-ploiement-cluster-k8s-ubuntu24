#!/bin/bash
# Script de test pour l'installation des plugins CNI
# À exécuter sur chaque nœud pour valider

echo "=== TEST D'INSTALLATION DES PLUGINS CNI ==="
echo "Date: $(date)"
echo "Nœud: $(hostname)"
echo ""

# Test 1: Vérifier la création du répertoire
echo "1. Vérification du répertoire /opt/cni/bin"
if [ -d "/opt/cni/bin" ]; then
    echo "✅ Répertoire /opt/cni/bin existe"
    ls -la /opt/cni/bin/ | wc -l | xargs echo "   Nombre de fichiers:"
else
    echo "❌ Répertoire /opt/cni/bin manquant"
fi
echo ""

# Test 2: Télécharger les plugins CNI
echo "2. Téléchargement des plugins CNI..."
cd /tmp
if wget -q https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz; then
    echo "✅ Téléchargement réussi"
    echo "   Taille du fichier: $(ls -lh cni-plugins-linux-amd64-v1.3.0.tgz | awk '{print $5}')"
else
    echo "❌ Échec du téléchargement"
fi
echo ""

# Test 3: Extraction
echo "3. Extraction des plugins CNI..."
if [ -f "/tmp/cni-plugins-linux-amd64-v1.3.0.tgz" ]; then
    sudo tar -xzf /tmp/cni-plugins-linux-amd64-v1.3.0.tgz -C /opt/cni/bin/
    if [ $? -eq 0 ]; then
        echo "✅ Extraction réussie"
    else
        echo "❌ Échec de l'extraction"
    fi
else
    echo "❌ Fichier d'archive non trouvé"
fi
echo ""

# Test 4: Vérification des plugins critiques
echo "4. Vérification des plugins critiques..."
critical_plugins=("loopback" "bridge" "host-local" "portmap" "bandwidth")

for plugin in "${critical_plugins[@]}"; do
    if [ -f "/opt/cni/bin/$plugin" ]; then
        echo "✅ Plugin $plugin présent"
    else
        echo "❌ Plugin $plugin MANQUANT"
    fi
done
echo ""

# Test 5: Liste complète des plugins
echo "5. Liste complète des plugins installés:"
if [ -d "/opt/cni/bin" ]; then
    ls -1 /opt/cni/bin/ | sort
else
    echo "Répertoire non accessible"
fi
echo ""

# Test 6: Permissions
echo "6. Vérification des permissions:"
ls -la /opt/cni/bin/ | head -5

echo ""
echo "=== FIN DU TEST ==="