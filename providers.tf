terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.39.0"
    }
    kubernetes = {
      source  = "hashicorp/google"
      version = "3.0.0-pre2"
      source  = "hashicorp/kubernetes"
      version = ">= 2.37.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "= 1.19.0"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster._.endpoint}"
#    config_path    = "~/.kube/config"

    client_certificate     = base64decode(google_container_cluster._.master_auth.0.client_certificate)
    client_key             = base64decode(google_container_cluster._.master_auth.0.client_key)
    cluster_ca_certificate = base64decode(google_container_cluster._.master_auth.0.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster._.endpoint}"
#  config_path    = "~/.kube/config"

  client_certificate     = base64decode(google_container_cluster._.master_auth.0.client_certificate)
  client_key             = base64decode(google_container_cluster._.master_auth.0.client_key)
  cluster_ca_certificate = base64decode(google_container_cluster._.master_auth.0.cluster_ca_certificate)

}


provider "kubectl" {
  host                   = "https://${google_container_cluster._.endpoint}"
  client_certificate     = base64decode(google_container_cluster._.master_auth.0.client_certificate)
  client_key             = base64decode(google_container_cluster._.master_auth.0.client_key)
  cluster_ca_certificate = base64decode(google_container_cluster._.master_auth.0.cluster_ca_certificate)
}
