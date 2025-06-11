# This blocks creates the Kubernetes cluster
resource "google_container_cluster" "_" {
  name     = var.kubernetes_name
  location = local.region

  node_pool {
    name = "builtin"
  }
  lifecycle {
    ignore_changes = [node_pool]
  }
}

# Creating and attaching the node-pool to the Kubernetes Cluster
resource "google_container_node_pool" "node-pool" {
  name               = "node-pool"
  cluster            = google_container_cluster._.id
  initial_node_count = 1

  node_config {
    preemptible  = false
    machine_type = "e2-standard-4" # 4 vCPU, 16 GB memory
  }
}

# Create the cluster role binding to give the user the privileges to create resources into Kubernetes
resource "kubernetes_cluster_role_binding" "cluster-admin-binding" {
  metadata {
    name = "cluster-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    name      = "${var.email}"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "kube-system"
  }
  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [google_container_cluster._, google_container_node_pool.node-pool]
}

# Install ECK operator via helm-charts
resource "helm_release" "elastic" {
  name = "elastic-operator"

  repository       = "https://helm.elastic.co"
  chart            = "eck-operator"
  namespace        = "elastic-system"
  create_namespace = "true"

  depends_on = [google_container_cluster._, google_container_node_pool.node-pool, kubernetes_cluster_role_binding.cluster-admin-binding]

}

# Delay of 30s to wait until ECK operator is up and running
resource "time_sleep" "wait_30_seconds" {
  depends_on = [helm_release.elastic]

  create_duration = "30s"
}

# Create Elasticsearch manifest
resource "kubectl_manifest" "elastic_quickstart" {
    yaml_body = <<YAML
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: es8181
spec:
  version: 8.18.1
  nodeSets:
  - config:
      node.roles:
      - master
      - data
      - ingest
      node.store.allow_mmap: false
    count: 1
    name: default
  - config:
      node.roles:
      - ml
      node.store.allow_mmap: false
      xpack.ml.enabled: true
      xpack.ml.max_model_memory_limit: 6Gb
    count: 1
    name: ml
    podTemplate:
      spec:
        containers:
        - name: elasticsearch
          resources:
            limits:
              memory: 6Gi
            requests:
              memory: 6Gi
YAML

  provisioner "local-exec" {
     command = "sleep 60"
  }
  depends_on = [helm_release.elastic, time_sleep.wait_30_seconds]
}

# Create Kibana manifest
resource "kubectl_manifest" "kibana_quickstart" {
    yaml_body = <<YAML
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kibana8151
spec:
  version: 8.18.1
  count: 1
  elasticsearchRef:
    name: es8181
YAML

  provisioner "local-exec" {
     command = "sleep 60"
  }
  depends_on = [helm_release.elastic, kubectl_manifest.elastic_quickstart]
}
