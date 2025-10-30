# Schéma d'infrastructure

Ce fichier contient un diagramme Mermaid représentant l'architecture utilisée par le dépôt : GitLab CI (hébergé sur Synology NAS) déclenche une pipeline qui exécute Ansible (runner) pour déployer un cluster Kubernetes sur 3 VM (1 master + 2 workers). La supervision/monitoring utilise Prometheus/Grafana (hébergé sur le NAS ou dans le cluster selon l'option choisie).

Copiez le bloc ci‑dessous dans un fichier `.md` ou directement dans un README pour que GitHub affiche le diagramme (GitHub prend en charge Mermaid si activé dans votre repo).

```mermaid
flowchart LR
  subgraph NAS_GitLab [Synology NAS / GitLab]
    GL[GitLab CI]
    ART["Artefacts<br>(kubeconfig, dashboard token)"]
    PROM_NAS[Prometheus / Grafana (NAS)]
  end

  subgraph CI_Runner [Runner / CI]
    Runner["GitLab Runner<br>(Ansible)"]
  end

  subgraph Infra [Cluster Kubernetes (Ubuntu VMs)]
  Master["Master VM<br>(kube-apiserver, controller, scheduler)"]
  Worker1["Worker VM 1<br>(kubelet, kube-proxy)"]
  Worker2["Worker VM 2<br>(kubelet, kube-proxy)"]

    subgraph ClusterServices [Services déployés]
      Dash[Kubernetes Dashboard]
  NodeExp["Node Exporter<br>(DaemonSet)"]
  KubeState["kube-state-metrics<br>(Deployment)"]
    end
  end

  %% Flèches principales
  GL -->|push / pipeline| Runner
  Runner -->|SSH / Ansible| Master
  Runner -->|SSH / Ansible| Worker1
  Runner -->|SSH / Ansible| Worker2

  Master -->|hosts pods & services| Dash
  Worker1 -->|hosts pods| NodeExp
  Worker2 -->|hosts pods| NodeExp
  KubeState -->|fournit métriques K8s| PROM_NAS

  NodeExp -->|scraped by| PROM_NAS
  Dash -->|token / kubeconfig ->| ART
  Runner -->|upload artefacts| ART
  GL -->|stocke artefacts| ART

  %% Option : Prometheus dans le cluster
  subgraph OptionalClusterProm [Prometheus dans le cluster (optionnel)]
    PROM_CLUSTER[Prometheus (Cluster)]
    GRAF_CLUSTER[Grafana (Cluster)]
  end

  NodeExp -->|scrape| PROM_CLUSTER
  KubeState -->|scrape| PROM_CLUSTER
  PROM_CLUSTER -->|dashboards| GRAF_CLUSTER
  GRAF_CLUSTER -->|visualise| Dash

  %% Lien entre NAS Prometheus et cluster
  PROM_NAS -- optional_scrape --> NodeExp
  PROM_NAS -- optional_scrape --> KubeState

  classDef infra fill:#f9f9f9,stroke:#333,stroke-width:1px;
  class NAS_GitLab,CI_Runner,Infra,ClusterServices,OptionalClusterProm infra;
```

Explication rapide :
- GitLab CI (sur NAS) contient la pipeline et stocke les artefacts (kubeconfig, token). Le runner exécute Ansible et se connecte en SSH aux VMs.
- Le master gère le plan de contrôle de Kubernetes et héberge le Dashboard.
- Les workers exécutent les workloads et exposent Node Exporter (daemonset) pour les métriques système.
- kube-state-metrics expose les métriques Kubernetes que Prometheus collecte.
- Prometheus/Grafana peut être hébergé soit sur le NAS (externe) soit dans le cluster (optionnel). Les deux options sont représentées.

