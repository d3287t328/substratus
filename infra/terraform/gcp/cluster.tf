data "google_container_engine_versions" "us-central1" {
  provider = google-beta
  location = var.region
}

resource "google_container_cluster" "main" {
  provider = google-beta

  name    = var.name
  project = var.project_id

  location           = var.region
  min_master_version = data.google_container_engine_versions.us-central1.release_channel_latest_version["REGULAR"]

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {}

  initial_node_count       = 1
  remove_default_node_pool = true

  node_config {
    machine_type = "e2-standard-2"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  identity_service_config {
    enabled = false
  }

  addons_config {
    config_connector_config {
      enabled = false
    }
    gcs_fuse_csi_driver_config {
      enabled = true
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
    maintenance_exclusion {
      exclusion_name = "stop being so disruptive GKE"
      start_time     = timestamp()
      # end is 179 days / 4296h from now
      end_time = timeadd(timestamp(), "4296h")
      exclusion_options {
        scope = "NO_MINOR_OR_NODE_UPGRADES"
      }
    }
  }

  enable_tpu = false

  cluster_autoscaling {
    enabled             = true
    autoscaling_profile = "OPTIMIZE_UTILIZATION"

    auto_provisioning_defaults {
      oauth_scopes = [
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/compute"
      ]
      management {
        auto_upgrade = true
        auto_repair  = true
      }
      disk_size = 100
      disk_type = "pd-ssd"
    }

    resource_limits {
      resource_type = "cpu"
      minimum       = 0
      maximum       = 96
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 0
      maximum       = 1048
    }
    resource_limits {
      resource_type = "nvidia-l4"
      minimum       = 0
      maximum       = 8
    }
    resource_limits {
      resource_type = "nvidia-tesla-t4"
      minimum       = 0
      maximum       = 4
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
      node_config,
      maintenance_policy["maintenance_exclusion"]
    ]
  }
}

resource "google_container_node_pool" "builder_1" {
  name = "builder-1"

  cluster            = google_container_cluster.main.id
  initial_node_count = 1
  node_locations     = [var.zone]

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  node_config {
    machine_type = "n2d-standard-8"
    ephemeral_storage_local_ssd_config {
      local_ssd_count = 1
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

# The L4 GPU does not support node autoprovisioning so precreating 0 size nodepool
resource "google_container_node_pool" "g2-standard-4" {
  name = "g2-standard-4"

  cluster            = google_container_cluster.main.id
  initial_node_count = 0
  node_locations     = [var.zone]

  autoscaling {
    min_node_count = 0
    max_node_count = 3
  }

  node_config {
    spot         = true
    machine_type = "g2-standard-4"
    guest_accelerator {
      type  = "nvidia-l4"
      count = 1
    }

    ephemeral_storage_local_ssd_config {
      local_ssd_count = 1
    }

    // gcs_config enables image streaming
    gcfs_config {
      enabled = true
    }

  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

resource "google_container_node_pool" "g2-standard-8" {
  name = "g2-standard-8"

  cluster            = google_container_cluster.main.id
  initial_node_count = 0
  node_locations     = [var.zone]

  autoscaling {
    min_node_count = 0
    max_node_count = 3
  }

  node_config {
    spot         = true
    machine_type = "g2-standard-8"
    guest_accelerator {
      type  = "nvidia-l4"
      count = 1
    }

    ephemeral_storage_local_ssd_config {
      local_ssd_count = 1
    }

    // gcs_config enables image streaming
    gcfs_config {
      enabled = true
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}


resource "google_container_node_pool" "g2-standard-24" {
  name = "g2-standard-24"

  cluster            = google_container_cluster.main.id
  initial_node_count = 0
  node_locations     = [var.zone]

  autoscaling {
    min_node_count = 0
    max_node_count = 3
  }

  node_config {
    spot         = true
    machine_type = "g2-standard-24"
    guest_accelerator {
      type  = "nvidia-l4"
      count = 2
    }
    ephemeral_storage_local_ssd_config {
      local_ssd_count = 2
    }

    // gcs_config enables image streaming
    gcfs_config {
      enabled = true
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

resource "google_container_node_pool" "g2-standard-48" {
  name = "g2-standard-48"

  cluster            = google_container_cluster.main.id
  initial_node_count = 0
  node_locations     = [var.zone]

  autoscaling {
    min_node_count = 0
    max_node_count = 3
  }

  node_config {
    spot         = true
    machine_type = "g2-standard-48"
    guest_accelerator {
      type  = "nvidia-l4"
      count = 4
    }

    ephemeral_storage_local_ssd_config {
      local_ssd_count = 4
    }
    // gcs_config enables image streaming
    gcfs_config {
      enabled = true
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}


resource "google_container_node_pool" "g2-standard-96" {
  name = "g2-standard-96"

  cluster            = google_container_cluster.main.id
  initial_node_count = 0
  node_locations     = [var.zone]

  autoscaling {
    min_node_count = 0
    max_node_count = 3
  }

  node_config {
    spot         = true
    machine_type = "g2-standard-96"
    guest_accelerator {
      type  = "nvidia-l4"
      count = 8
    }

    ephemeral_storage_local_ssd_config {
      local_ssd_count = 8
    }
    // gcs_config enables image streaming
    gcfs_config {
      enabled = true
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}