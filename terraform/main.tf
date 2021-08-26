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
  zone    = var.zone
}

# Enable Cloud Run API
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"

  disable_on_destroy = true
}

resource "google_cloud_run_service" "api" {
  name     = "fullstack-tf-api"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project}/fullstack_api:latest"

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
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.run_api
  ]
}

resource "google_cloud_run_service" "web" {
  name     = "fullstack-tf-web"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project}/fullstack_web:latest"

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
