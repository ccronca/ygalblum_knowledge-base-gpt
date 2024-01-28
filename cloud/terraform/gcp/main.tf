data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "google_compute_zones" "available" {
}

locals {
  myip_cidr = "${chomp(data.http.myip.response_body)}/32"
  zone = data.google_compute_zones.available.names[0]
}

resource "google_compute_instance" "ollama" {
  boot_disk {
    auto_delete = true
    device_name = "${var.name}"

    initialize_params {
      image = var.boot_image
      size  = var.boot_image_size
      type  = "pd-ssd"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  guest_accelerator {
    count = 1
    type  = "projects/${var.gcp_project}/zones/${local.zone}/acceleratorTypes/nvidia-tesla-t4"
  }

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = var.machine_type

  metadata = {
    ssh-keys = var.ssh_public_key
  }

  name = "${var.name}"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    subnetwork = google_compute_subnetwork.this.id
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "TERMINATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email = var.service_account
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/drive.readonly"
    ]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = [
    "${var.name}-ssh",
    "${var.name}-gradio",
    "${var.name}-secured-ollama"
  ]
  zone = local.zone
}
