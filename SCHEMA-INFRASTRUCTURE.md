# 🏗️ SCHÉMA COMPLET DE L'INFRASTRUCTURE KUBERNETES + GITLAB CI/CD

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    🌐 RÉSEAU LOCAL 192.168.1.x                                    │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                     │
│  ┌─────────────────────┐         ┌─────────────────────────────────────────────────────────────┐  │
│  │   💻 PC WINDOWS     │         │              🐳 CLUSTER KUBERNETES                         │  │
│  │   192.168.1.xxx     │  SSH    │                                                             │  │
│  │                     │◄───────►│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │  │
│  │ • kubectl           │         │  │   🎯 MASTER     │  │   👷 WORKER-1   │  │ 👷 WORKER-2│ │  │
│  │ • helm (optionnel)  │         │  │ 192.168.1.72    │  │ 192.168.1.73    │  │192.168.1.74│ │  │
│  │ • ~/.kube/config    │         │  │                 │  │                 │  │             │ │  │
│  │ • VS Code           │         │  │ • API Server    │  │ • kubelet       │  │• kubelet    │ │  │
│  └─────────────────────┘         │  │ • etcd          │  │ • kube-proxy    │  │• kube-proxy │ │  │
│           │                      │  │ • scheduler     │  │ • flannel       │  │• flannel    │ │  │
│           │ HTTP                 │  │ • controller    │  │                 │  │             │ │  │
│           ▼                      │  │ • flannel       │  │ PODS:           │  │PODS:        │ │  │
│  ┌─────────────────────┐         │  │ • kubeconfig    │  │ nginx-app-xxx   │  │nginx-app-xxx│ │  │
│  │ 🏠 NAS SYNOLOGY     │  SSH    │  │                 │  │                 │  │             │ │  │
│  │ 192.168.1.253       │◄───────►│  └─────────────────┘  └─────────────────┘  └─────────────┘ │  │
│  │                     │         │                                                             │  │
│  │ ┌─────────────────┐ │         │           ⚡ NodePort Services ⚡                          │  │
│  │ │🦊 GITLAB SERVER │          │           nginx: 30090 → 🌐 http://192.168.1.72:30090      │  │
│  │ │ Port: 7878      │ │         └─────────────────────────────────────────────────────────────┘  │
│  │ │                 │ │                                                                           │
│  │ │• Repos Git      │ │                                                                           │
│  │ │• GitLab CI/CD   │ │                                                                           │
│  │ │• Variables      │ │                                                                            │
│  │ │• SSH_PRIVATE_KEY│ │                                                                           │
│  │ └─────────────────┘ │                                                                           │
│  │                     │                                                                           │
│  │ ┌─────────────────┐ │                                                                           │
│  │ │🐳 DOCKER ENGINE │ │                                                                           │
│  │ │ DSM 7.x         │ │                                                                           │
│  │ │ ┌─────────────┐ │ │                                                                           │
│  │ │ │GITLAB RUNNER│ │ │                                                                           │
│  │ │ │Container    │ │ │                                                                           │
│  │ │ │             │ │ │                                                                           │
│  │ │ │• runner-    │ │ │                                                                           │
│  │ │ │  devops:    │ │ │                                                                           │
│  │ │ │  latest     │ │ │                                                                           │
│  │ │ │• kubectl    │ │ │                                                                           │
│  │ │ │• helm v3.19 │ │ │                                                                           │
│  │ │ │• ssh client │ │ │                                                                           │
│  │ │ │• git        │ │ │                                                                           │
│  │ │ │• tag:synogy │ │ │                                                                           │
│  │ │ └─────────────┘ │ │                                                                           │
│  │ └─────────────────┘ │                                                                           │
│  └─────────────────────┘                                                                           │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 FLUX DE DÉPLOIEMENT COMPLET

```
1️⃣ DÉVELOPPEMENT (PC Windows)
   │
   │ git push
   ▼
2️⃣ NAS SYNOLOGY (192.168.1.253)
   │ ┌─► 🦊 GITLAB SERVER (port 7878)
   │ │   └─► Détecte push → Lance pipeline
   │ │  
   │ └─► 🐳 DOCKER ENGINE (DSM)
   │     └─► Lance GitLab Runner Container
   │         └─► mon-runner-devops:latest
   │
   │ SSH + kubeconfig
   ▼  
3️⃣ CLUSTER KUBERNETES (3 VMs)
   │ Master (72) + Workers (73,74)
   │
   │ helm upgrade --install
   ▼
4️⃣ APPLICATIONS DÉPLOYÉES
   └─► 🌐 http://192.168.1.72:30090 (nginx)
```

## 📋 COMPOSANTS DÉTAILLÉS

### 🖥️ **PC Windows (Station de travail)**
- **OS**: Windows 11/10  
- **Outils**: kubectl v1.34.1, VS Code, Git, PowerShell
- **Config**: `~/.kube/config` (copié du master K8s)
- **Accès**: SSH vers cluster, HTTP vers GitLab

### 🏠 **NAS Synology (192.168.1.253) - CŒUR DE L'INFRASTRUCTURE**
#### **🦊 GitLab Server (Port 7878)**
- **Services**: GitLab Community Edition sur DSM
- **Repos**: ansible-k8s-cluster
- **CI/CD**: Pipelines automatiques sur push  
- **Variables**: SSH_PRIVATE_KEY, K8S_MASTER_IP
- **Interface**: http://192.168.1.253:7878

#### **🐳 Docker Engine (DSM Container Manager)**
- **OS**: Synology DSM 7.x
- **Service**: Docker intégré DSM
- **Runner**: gitlab-runner-docker USN5gs-TS
- **Tag**: synology (pour cibler ce runner)

#### **🚀 GitLab Runner Container**
- **Image**: mon-runner-devops:latest
- **Outils inclus**: kubectl, helm v3.19.0, ssh, git
- **Exécution**: Jobs sur branches test-*
- **Authentification**: SSH keys pour accès cluster

### ☸️ **Cluster Kubernetes (3 VMs séparées)**

-#### **🎯 Master (192.168.1.72)**
- **Rôle**: control-plane
- **Version**: v1.31.15  
- **Services**: API Server (6443), etcd, scheduler, controller-manager
- **Réseau**: Flannel CNI
- **Config**: ~/.kube/config (source pour tous)

#### **👷 Worker-1 (192.168.1.73)**
- **Rôle**: worker node
- **Services**: kubelet, kube-proxy, flannel
- **Pods**: nginx-release-nginx-app (1/3 replicas)

#### **👷 Worker-2 (192.168.1.74)** 
- **Rôle**: worker node
- **Services**: kubelet, kube-proxy, flannel  
- **Pods**: nginx-release-nginx-app (2/3 replicas)

## 🚀 APPLICATIONS HELM DÉPLOYÉES

### **📦 nginx-release (Chart nginx-app)**
- **Replicas**: 3 pods distribués sur workers
- **Service**: NodePort 30090
- **Access**: http://192.168.1.72:30090
- **Gestion**: `helm list`, `helm upgrade`, `helm rollback`

## 🔧 FICHIERS DE CONFIGURATION

### **📁 Structure du projet**
```
ansible-k8s-cluster/
├── .gitlab-ci.yml              # Pipeline GitLab CI/CD
├── helm-charts/
│   └── nginx-app/
│       ├── Chart.yaml          # Métadonnées Helm
│       ├── values.yaml         # Configuration (replicas, ports)
│       └── templates/
│           ├── _helpers.tpl    # Fonctions Helm
│           ├── deployment.yaml # Template pods nginx
│           └── service.yaml    # Template service NodePort
└── README.md
```

### **⚙️ Pipeline Jobs**
- **test_helm**: Vérifie Helm + connexion cluster
- **deploy_helm_app**: Déploie nginx avec Helm (auto sur test-*)
- **deploy_test_app**: Job kubectl manuel (legacy)

## 🌐 ACCÈS ET PORTS

| Service | Machine | IP/URL | Port | Protocole | Description |
|---------|---------|--------|------|-----------|-------------|
| GitLab | NAS Synology | 192.168.1.253 | 7878 | HTTP | Interface web GitLab |
| Docker | NAS Synology | 192.168.1.253 | - | Local | Container Manager DSM |
| K8s API | VM Master | 192.168.1.72 | 6443 | HTTPS | API Kubernetes |
| nginx | Cluster K8s | 192.168.1.72-74 | 30090 | HTTP | Application web nginx |
| SSH | VM Master | 192.168.1.72 | 22 | SSH | Accès master pour kubeconfig |

## 🔐 SÉCURITÉ ET AUTHENTIFICATION

- **SSH Keys**: GitLab CI/CD → Cluster K8s (Runner container → VMs)
- **kubeconfig**: Certificats TLS pour API K8s
- **RBAC**: Permissions Kubernetes (via kubeconfig)
- **Variables GitLab**: SSH_PRIVATE_KEY protégée/masquée
- **Réseau**: Tout en local 192.168.1.x

## 🏆 **INFRASTRUCTURE COMPLÈTE : 6 MACHINES**

1. **💻 PC Windows** - Développement + kubectl
2. **🏠 NAS Synology** - GitLab + Docker Runner  
3. **🎯 VM Master K8s** - Control plane (192.168.1.72)
4. **👷 VM Worker-1** - Nœud travail (192.168.1.73)
5. **👷 VM Worker-2** - Nœud travail (192.168.1.74)
6. **🌐 Browser/Client** - Accès applications

## 🎯 AVANTAGES DE CETTE ARCHITECTURE

✅ **Centralisation NAS**: GitLab + Runner sur même machine  
✅ **Automatisation complète**: Push → Deploy  
✅ **Haute disponibilité**: 3 nœuds K8s  
✅ **Gestion moderne**: Helm charts  
✅ **Accès multiple**: Windows + GitLab  
✅ **Scalabilité**: Ajout workers facile  
✅ **Rollback**: Helm history/rollback  
✅ **Synology**: Infrastructure stable et fiable  

---
*Schéma corrigé avec NAS Synology - 16 octobre 2025* 🏠🚀