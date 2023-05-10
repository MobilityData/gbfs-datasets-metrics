/**
 * MobilityData 2023
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

provider "google" {
  project = var.project_id
}

resource "google_project_service" "workflows" {
  service            = "workflows.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "workflows_service_account" {
  account_id   = "workflows-sa"
  display_name = "Workflows Service Account"
}

resource "google_project_iam_member" "log_binding" {
  project = var.project_id
  role    = "roles/logging.logWriter" #logging.logEntries.create
  member  = "serviceAccount:${google_service_account.workflows_service_account.email}"
}

resource "google_project_iam_member" "workflow_executor_binding" {
  project = var.project_id
  role    = "roles/workflows.invoker" #workflows.executions.create
  member  = "serviceAccount:${google_service_account.workflows_service_account.email}"
}

resource "google_project_iam_member" "workflow_admin_binding" {
  project = var.project_id
  role    = "roles/workflows.admin" #workflows.executions.create
  member  = "serviceAccount:${google_service_account.workflows_service_account.email}"
}

resource "google_storage_bucket" "mobilitydata-gbfs-validation-results" {
  name          = "mobilitydata-gbfs-validation-results"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}

resource "google_storage_bucket_iam_member" "bucket_member" {
  bucket = google_storage_bucket.mobilitydata-gbfs-validation-results.name
  role   = "roles/storage.objectAdmin"

  member = "serviceAccount:${google_service_account.workflows_service_account.email}"
}

resource "google_workflows_workflow" "workflow-gbfs-validator" {
  name            = "workflow-gbfs-validator"
  region          = var.gcp_region
  description     = "GBFS Validator Workflow"
  service_account = google_service_account.workflows_service_account.id
  source_contents = templatefile("./workflow-gbfs-validator.yaml", { app_gbs_validator_url = "${var.app_gbs_validator_url}"})
  depends_on = [google_project_service.workflows]
}

resource "google_workflows_workflow" "workflow-gbfs-catalog-validator" {
  name            = "workflow-gbfs-catalog-validator"
  region          = var.gcp_region
  description     = "GBFS Validator Workflow"
  service_account = google_service_account.workflows_service_account.id
  source_contents = "${file("./workflow-gbfs-catalog-validator.yaml")}"

  depends_on = [google_project_service.workflows]
}

## Big Query

resource "google_bigquery_dataset" "gbfs-results-dataset" {
  dataset_id                  = var.gbfs_results_dataset_id
  friendly_name               = "gbfs_results"
  description                 = "GBFS Validation Results Dataset"
  location                    = var.gbfs_results_dataset_location
  #default_table_expiration_ms = 3600000
}

resource "google_bigquery_table" "executions_results_table" {
  dataset_id = var.gbfs_results_dataset_id
  table_id = var.gbfs_results_dataset_table_id

   schema = "${file("./executions-results-schema.json")}"

   depends_on = [ google_bigquery_dataset.gbfs-results-dataset ]
}

