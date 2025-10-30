# Déploiement Automatisé d’un Cluster Kubernetes — version simplifiée pour débutants

Ce dépôt automatise l'installation d'un petit cluster Kubernetes (1 master + 2 workers) sur des machines Ubuntu 24.04 en utilisant Ansible. Il inclut aussi des exemples pour déployer un dashboard Kubernetes et une stack de monitoring (Prometheus + Grafana).

Cette version du README est réorganisée pour les débutants : étapes claires, commandes à copier/coller, et deux modes d'exécution (avec ou sans CI/CD).

## Sommaire
- Prérequis
- Structure du dépôt
- Déploiement rapide (avec GitLab CI)
- Déploiement sans CI/CD (manuel)
- Accès aux services
- Monitoring
- Pipeline GitLab CI (aperçu)
- Dépannage rapide
- Spécifications techniques & gestion des versions

## 📝 Prérequis

- 3 machines Ubuntu 24.04 (ou plus) : une master, deux workers (ou équivalent)
- Accès SSH depuis la machine où vous lancerez Ansible
- Ansible installé localement (ou via la CI)
- (Optionnel) Compte GitLab + Runner (ici utilisé sur un Synology NAS)

## 📁 Structure du dépôt

Principaux fichiers et dossiers :

- `.gitlab-ci.yml` — pipeline GitLab CI
- `inventory/inventory.yml` — inventaire Ansible (mettez-y vos IPs)
- `playbooks/` — playbooks Ansible (site.yml, cleanup-playbook.yml, ...)
- `group_vars/all.yml` — variables globales (versions)
- `roles/` — rôles Ansible (common, containerd, kubernetes, master, worker)
- `configs/` — manifests Kubernetes (dashboard, monitoring)
- `scripts/` — scripts d'aide (préparation VM, tests CNI)

## ⚡ Déploiement rapide (avec GitLab CI)

1. Dans GitLab, définissez les variables CI/CD (Settings > CI/CD > Variables) :

```bash
# Exemple
K8S_MASTER_IP=192.168.1.72
K8S_WORKER1_IP=192.168.1.73
K8S_WORKER2_IP=192.168.1.74
SSH_PRIVATE_KEY="<votre clé privée>"
```

2. Poussez sur `main` :

```bash
git push origin main
# La pipeline GitLab CI s'exécute et lance les playbooks
```

3. Récupérez les artefacts (kubeconfig, dashboard token, configs monitoring) depuis l'interface GitLab pour accéder au cluster et aux services.

## 🛠️ Déploiement sans CI/CD (manuel)

Si vous préférez ou si vous apprenez, vous pouvez exécuter Ansible localement :

1. Éditez `inventory/inventory.yml` et ajoutez les IP de vos machines.

2. Testez la connectivité Ansible :

```bash
ansible all -i inventory/inventory.yml -m ping
```

3. Déployez tout le cluster :

```bash
ansible-playbook -i inventory/inventory.yml playbooks/site.yml
```

4. Exécuter par étapes (utile pour l'apprentissage) :

```bash
ansible-playbook -i inventory/inventory.yml playbooks/site.yml --tags common
ansible-playbook -i inventory/inventory.yml playbooks/site.yml --tags containerd
ansible-playbook -i inventory/inventory.yml playbooks/site.yml --tags kubernetes
ansible-playbook -i inventory/inventory.yml playbooks/site.yml --limit masters
ansible-playbook -i inventory/inventory.yml playbooks/site.yml --limit workers
```

Ce mode est idéal pour expérimenter et comprendre chaque étape.

## 🌐 Accès aux services

- Dashboard Kubernetes : https://[IP_MASTER]:30443 (récupérer le token dans les artefacts ou via les guides)
- Node Exporter : http://[IP_MASTER]:9100/metrics (ciblé par Prometheus)
- kube-state-metrics : http://[IP_MASTER]:30080/metrics

Pour utiliser `kubectl` localement après récupération du kubeconfig :

```bash
export KUBECONFIG=./kubeconfig/config
kubectl get nodes
```

## 📊 Monitoring

La stack déployée contient :

- Node Exporter (DaemonSet) — métriques des nœuds
- kube-state-metrics (Deployment) — métriques Kubernetes
- Assets et configurations pour intégrer Prometheus/Grafana (voir `PROMETHEUS_INTEGRATION.md`)

Intégration rapide (script d'exemple) :

```bash
./integrate-monitoring.sh <master_ip> <nas_ip>
```

Dashboards Grafana recommandés : Kubernetes Cluster Monitoring, Kubernetes Pod Monitoring, Node Exporter Full.

## 🔧 Pipeline GitLab CI — aperçu

Pipeline en 5 stages :

1. validate — vérifications (syntax, SSH)
2. prepare — préparation des artefacts
3. deploy-cluster — exécution des playbooks
4. verify — tests et vérifications (kubectl, dashboard)
5. deploy-app — déploiement d'apps/tests (manuel pour monitoring)

Jobs manuels disponibles : `deploy_monitoring`, `deploy_test_app`, `cleanup_cluster`.

## 🚨 Dépannage rapide

- Nœuds NotReady :

```bash
kubectl describe node <node-name>
kubectl get pods -n kube-system
```

- Pipeline CI échoue : vérifiez les variables CI/CD et testez la connexion SSH :

```bash
ssh user@<ip> "uptime"
```

- Dashboard inaccessible :

```bash
kubectl get pods -n kubernetes-dashboard
kubectl get svc -n kubernetes-dashboard
```

- Monitoring : vérifiez les pods et endpoints de Node Exporter/kube-state-metrics.

## 📈 Spécifications techniques & gestion des versions

- Kubernetes : v1.31.2 (exemple, piloté depuis `group_vars/all.yml`)
- Containerd : v1.7.8
- CNI : Flannel v0.22.3
- Dashboard : v2.7.0

Les versions utilisées sont centralisées dans `group_vars/all.yml`. Pour changer une version, mettez à jour la variable correspondante puis relancez les playbooks dans un environnement de test.

## Liens et guides

- `GITLAB_CI_SETUP.md` — configuration GitLab CI sur Synology
- `PROMETHEUS_INTEGRATION.md` — guide d'intégration Prometheus/Grafana
- `DASHBOARD_GUIDE.md` — guide d'utilisation du dashboard Kubernetes

---
