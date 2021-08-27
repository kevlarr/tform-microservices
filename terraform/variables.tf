variable "project" {}

variable "credentials_file" {}

variable "database_url" {}

variable "cloud_sql_name" {}

variable "region" {
  default = "us-east4"
}

variable "zone" {
  default = "us-east4-c"
}
