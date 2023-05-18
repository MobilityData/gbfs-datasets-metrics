variable "project_id" {
  type = string
  description = "GCP project ID"
}

variable "gcp_region" {
  type = string
  description = "GCP region"
}

variable "app_gbs_validator_url" {
  type = string
  description = "GBFS Validator API URL"
}

variable "gbfs_results_dataset_id" {
  type = string
  description = "GBFS BigQuery table Id"
  default = "gbfs_results_dataset"
}

variable "gbfs_results_dataset_location" {
  type = string
  description = "GBFS BigQuery table location"
  default = "US"
}

variable "gbfs_results_dataset_table_id" {
  type = string
  description = "GBFS BigQuery table location"
  default = "gbfs_results"
}



