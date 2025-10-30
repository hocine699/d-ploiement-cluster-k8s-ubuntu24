#!/bin/bash

# Script de configuration post-installation pour VMs Ubuntu
# À exécuter sur chaque VM après l'installation initiale

set -e

echo "🔧 Configuration post-installation pour Ansible/Kubernetes"
echo "=========================================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Obtenir le nom d'utilisateur actuel
CURRENT_USER=$(whoami)

# 1. Configuration sudo sans mot de passe
log_info "Configuration sudo sans mot de passe pour $CURRENT_USER..."
echo "$CURRENT_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$CURRENT_USER
sudo chmod 440 /etc/sudoers.d/$CURRENT_USER
log_success "Sudo sans mot de passe configuré"

# 2. Configuration SSH
log_info "Configuration du serveur SSH..."

# Backup du fichier original
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Configuration SSH optimisée
sudo tee /etc/ssh/sshd_config > /dev/null << 'EOF'
# Configuration SSH pour Ansible/Kubernetes

# Port et protocole
Port 22
Protocol 2

# Authentification
PubkeyAuthentication yes
PasswordAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Sécurité
PermitRootLogin no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Paramètres de connexion
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*

# Subsystem
Subsystem sftp /usr/lib/openssh/sftp-server

# Optimisations pour Ansible
ClientAliveInterval 60
ClientAliveCountMax 3
MaxSessions 10
MaxStartups 10:30:100
EOF

log_success "Configuration SSH mise à jour"

# 3. Redémarrage du service SSH
log_info "Redémarrage du service SSH..."
sudo systemctl restart ssh
sudo systemctl enable ssh
log_success "Service SSH redémarré"

# 4. Configuration du firewall pour SSH
log_info "Configuration du firewall..."
sudo ufw allow ssh
sudo ufw --force enable
log_success "Firewall configuré"

# 5. Création du dossier .ssh avec bonnes permissions
log_info "Configuration du dossier .ssh..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
log_success "Dossier .ssh configuré"

# 6. Installation des paquets requis pour Kubernetes
log_info "Installation des paquets requis..."
sudo apt update
sudo apt install -y \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    python3 \
    python3-pip
log_success "Paquets installés"

# 7. Configuration système pour Kubernetes
log_info "Configuration système pour Kubernetes..."

# Désactiver le swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
log_success "Swap désactivé"

# Modules kernel requis
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Paramètres sysctl pour Kubernetes
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
log_success "Configuration système appliquée"

# 8. Affichage des informations finales
echo ""
echo "=========================================================="
log_success "Configuration terminée ! 🎉"
echo "=========================================================="
echo ""
log_info "Résumé des configurations appliquées :"
echo "• Sudo sans mot de passe pour $CURRENT_USER"
echo "• Configuration SSH optimisée pour Ansible"
echo "• Firewall configuré (SSH autorisé)"
echo "• Dossier .ssh créé avec bonnes permissions"
echo "• Paquets requis installés"
echo "• Système configuré pour Kubernetes (swap désactivé)"
echo ""
log_warning "Actions suivantes :"
echo "1. Ajoutez votre clé publique SSH dans ~/.ssh/authorized_keys"
echo "2. Testez la connexion SSH sans mot de passe"
echo "3. Lancez le pipeline GitLab Ansible"
echo ""

# Affichage de la clé publique à ajouter (si elle existe)
if [ -f ~/.ssh/id_rsa.pub ]; then
    log_info "Clé publique trouvée :"
    cat ~/.ssh/id_rsa.pub
else
    log_info "Pour ajouter votre clé publique :"
    echo "echo 'ssh-rsa AAAAB3NzaC1... votre-cle-publique' >> ~/.ssh/authorized_keys"
fi

echo ""
log_info "VM prête pour le déploiement Kubernetes via Ansible !"