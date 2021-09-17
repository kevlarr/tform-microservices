terraform {
  required_version = ">= 0.14"

  backend "gcs" {
    prefix = "terraform/fullstacktf"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.81"
    }
  }
}

provider "google" {
  credentials = var.credentials
  project = var.project
  region  = var.region
}

##
## Specific APIs need to be enabled prior to creating any services
##

resource "google_project_service" "resource_manager_api" {
  project = var.project
  service = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = true
}

resource "google_project_service" "compute_api" {
  project = var.project
  service = "compute.googleapis.com"

  disable_on_destroy = true
}
resource "google_project_service" "run_api" {
  project = var.project
  service = "run.googleapis.com"

  disable_on_destroy = true
}
resource "google_project_service" "vpcaccess_api" {
  project = var.project
  service = "vpcaccess.googleapis.com"

  disable_on_destroy = true
}

##
## Cloud Run services can only connect to Cloud SQL via a "private IP"
## by way of a VPN, connectors, etc.
##
resource "google_compute_network" "private_network" {
  name = "tf-private-network"
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "tf-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

}

##
## The Cloud SQL database server itself; this does not create the database
## 'proper' inside the server that the app will connect to. That needs to
## be done outside (via console or command-line remote access) I think.
##
resource "google_sql_database_instance" "database" {
  name             = "tftest-instance"
  database_version = "POSTGRES_13"
  region           = var.region

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      private_network = google_compute_network.private_network.id
    }
  }

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
  ]
}

##
## Creates a new user for the API.
##
## TODO Not sure how (specific to Google Cloud) to tie a database
## to a specific user; hopefully this is enough for the user to
## have meaningful permissions (ie. create tables, etc)
##
resource "google_sql_user" "sql_user" {
  name     = var.database_username
  password = var.database_password
  instance = google_sql_database_instance.database.name
}

##
## Cloud Run services aren't directly associated to a VPC; there needs to
## be a separate "VPC connector" layer
##
resource "google_vpc_access_connector" "connector" {
  name          = "fullstack-tf-vpc-con"
  ip_cidr_range = "10.8.0.0/28"
  #network       = "default"
  network = google_compute_network.private_network.name

  depends_on = [
    google_compute_network.private_network,
    google_project_service.vpcaccess_api
  ]
}

##
## The API is dependent on the database, and care must be taken to build the
## SQLAlchemy connection string properly (especially grabbing the private IP
## address from the database rather than the "private_ip_address" service).
##
resource "google_cloud_run_service" "api" {
  name     = "fullstack-tf-api"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project}/fullstack_api:${var.docker_tag}"

        env {
          name  = "HOST"
          value = "0.0.0.0"
        }

        env {
          name  = "SQLALCHEMY_URL"
          value = "postgresql://${google_sql_user.sql_user.name}:${google_sql_user.sql_user.password}@${google_sql_database_instance.database.private_ip_address}:5432/tftest"
        }
      }
    }

    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = "fullstack-tf-vpc-con"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.run_api,
    google_project_service.vpcaccess_api,
    google_vpc_access_connector.connector,
  ]
}

##
## The front-end server, which only needs access to the API's URL
## and is pretty simple otherwise
##
resource "google_cloud_run_service" "web" {
  name     = "fullstack-tf-web"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project}/fullstack_web:${var.docker_tag}"

        env {
          name  = "HOST"
          value = "0.0.0.0"
        }

        env {
          name  = "API_URL"
          value = google_cloud_run_service.api.status[0].url
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.run_api,
    google_cloud_run_service.api,
  ]
}

##
## Cloud Run idles containers (throttles their CPU to near-zero) some unspecified
## amount of time after they stop receiving requests, which prevents background
## work from completing.
##
## Cloud Scheduler can only fire once every minute at its most frequent, which won't
## be enough to make sure the API is *ALWAYS* up, but from tests so far it keeps an
## otherwise-inactive container up 75% - 95% of the time, which is enough for the
## small amount of background work we need to perform.
##
resource "google_cloud_scheduler_job" "updater" {
  name        = "fullstack-tf-api-ping"
  description = "Pings the API every minute to try to keep the container active so background tasks can run"
  schedule    = "* * * * *"

  http_target {
    http_method = "GET"
    uri         = google_cloud_run_service.api.status[0].url
  }

  depends_on = [
    google_cloud_run_service.api,
  ]
}

##
## Cloud Run by default can't be executed by anybody, so either
## authentication is required to be set up or, for public services
## that are open to anyone, the "allUsers" stuff is required
##
resource "google_cloud_run_service_iam_member" "api_all_users" {
  service  = google_cloud_run_service.api.name
  location = google_cloud_run_service.api.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "web_all_users" {
  service  = google_cloud_run_service.web.name
  location = google_cloud_run_service.web.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
