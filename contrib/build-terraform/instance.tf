provider "google" {
  project     = "jetstack-gke"
  region      = "europe-west1"
  credentials = "${file("~/.gcloud/jetstack-gke.json")}"
}

resource "google_compute_instance" "build" {
  name         = "openshift-build"
  machine_type = "n1-highmem-8"
  zone         = "europe-west1-b"

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  disk {
    image = "centos-7"
  }

  metadata_startup_script = "${file("setup-os-build.sh")}"

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

output "instance_ip" {
  value = "${google_compute_instance.build.network_interface.0.access_config.0.assigned_nat_ip}"
}
