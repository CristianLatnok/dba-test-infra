provider "google" {
  credentials = file("/json/test-dba.json")
  project     = "prueba-tecnica-396100"
  region      = "us-central1"
}

resource "random_id" "db_password" {
  byte_length = 12
}

resource "google_compute_network" "vpc_network" {
  name                    = "vpc-test-dba-gcp-01"
  auto_create_subnetworks = false
  provider                = google-beta
}

resource "google_compute_subnetwork" "vm_subnetwork" {
  name          = "subnet-network-test-dba-01"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc_network.self_link
}

resource "google_compute_subnetwork" "db_subnetwork" {
  name          = "subnet-network-test-dba-02"
  ip_cidr_range = "10.0.2.0/24"
  network       = google_compute_network.vpc_network.self_link
}

resource "google_compute_router" "cloud_router" {
  name    = "router-test-dba"
  region  = "us-central1"
  network = google_compute_network.vpc_network.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "cloud_nat" {
  name                   = "nat-gcp-test-dba"
  router                 = google_compute_router.cloud_router.name
  region                 = google_compute_router.cloud_router.region
  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_global_address" "priv_ip_address" {
  provider = google-beta

  name          = "priv-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  network       = google_compute_network.vpc_network.self_link
}

resource "google_service_networking_connection" "priv_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.priv_ip_address.name]
}

resource "google_sql_database_instance" "database_instance" {
  name             = "db-sql-postgresql-test-dba-01"
  database_version = "POSTGRES_13"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"
    deletion_protection_enabled = false

    user_labels = {
      environment = "production"
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_subnetwork.db_subnetwork.network
      enable_private_path_for_google_cloud_services = true
      require_ssl     = false
    }

    database_flags {
      name  = "max_connections"
      value = "500"
    }

  }
}

resource "google_sql_database_instance" "database_replica" {
  name                 = "db-sql-postgresql-test-dba-replica"
  database_version     = google_sql_database_instance.database_instance.database_version
  region               = google_sql_database_instance.database_instance.region
  master_instance_name = google_sql_database_instance.database_instance.name

  settings {
    tier = "db-f1-micro"
    deletion_protection_enabled = false

    user_labels = {
      environment = "production"
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_subnetwork.db_subnetwork.network
      enable_private_path_for_google_cloud_services = true
      require_ssl     = false
    }

    database_flags {
      name  = "max_connections"
      value = "500"
    }

  }
}

provider "google-beta" {
  project = "prueba-tecnica-396100"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_sql_user" "database_user" {
  name     = "db-user-admin"
  instance = google_sql_database_instance.database_instance.name
  password = random_id.db_password.hex
}

resource "google_storage_bucket" "config_bucket" {
  name     = "storage-dba-us-central1-0001"
  location = "us-central1"
  force_destroy = true
}

resource "google_storage_bucket_object" "storage_object" {
  name   = "storage-object.txt"
  bucket = google_storage_bucket.config_bucket.name
  source = "file.txt"
}

resource "google_compute_instance" "vm_instance" {
  name         = "vm-instance-test-dba-01"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.vm_subnetwork.name
    access_config {
      nat_ip = google_compute_address.public_ip_vm.address
    }
  }

  metadata_startup_script = file("setup.sh")
}

resource "google_compute_address" "public_ip_vm" {
  name = "public-ip-test-dba-01"
}

resource "google_compute_firewall" "vm_firewall" {
  name    = "allow-http-ssh"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["80", "22", "5000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-egress" {
  name      = "allow-egress"
  direction = "EGRESS"
  network   = google_compute_network.vpc_network.self_link

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "link_sql" {
  name    = "comunication-sql"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = ["10.0.1.0/24"]
}
