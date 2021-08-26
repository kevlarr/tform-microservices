output "web_url" {
  value = google_cloud_run_service.web.status[0].url
}

output "api_url" {
  value = google_cloud_run_service.api.status[0].url
}
