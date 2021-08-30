terraform {
  required_version = ">= 0.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.81"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
}

# Enable Cloud Run API
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

resource "google_vpc_access_connector" "connector" {
  name          = "fullstack-tf-vpc-con"
  ip_cidr_range = "10.8.0.0/28"
  network       = "default"

  depends_on = [
    google_project_service.vpcaccess_api
  ]
}

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
          value = var.database_url
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
