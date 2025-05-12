variable "account_id" {
  type = string
}
variable "project" {
  type    = string
  default = ""
}
variable "iam_roles" {
  type = any
  # TODO: Use this instead when `optional()` is no longer experimental
  # type = list(object({
  #   role = string
  #   type = string
  #   name = string
  #   project = optional(string)
  # })
}

locals {
  # Convert `var.iam_roles` into a `for_each` map
  iam_roles = {
    for x in flatten([
      for rule in var.iam_roles : [
        for role in rule.roles : {
          role    = role
          type    = rule.type
          name    = rule.name
          project = lookup(rule, "project", var.project)
        }
      ]
    ]) : join("-", [x.type, x.name, x.role]) => x
  }
}

resource "google_service_account" "env" {
  account_id = var.account_id
  project    = var.project
}

resource "google_project_iam_member" "env" {
  for_each = {
    for k, v in local.iam_roles : k => v
    if v.type == "project"
  }
  project = each.value.name
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.env.email}"
}

resource "google_storage_bucket_iam_member" "env" {
  for_each = {
    for k, v in local.iam_roles : k => v
    if v.type == "bucket"
  }

  bucket = each.value.name
  role   = each.value.role
  member = "serviceAccount:${google_service_account.env.email}"
}

resource "google_secret_manager_secret_iam_member" "env" {
  for_each = {
    for k, v in local.iam_roles : k => v
    if v.type == "secret"
  }


  project   = lookup(each.value, "project", "") != "" ? each.value.project : var.project
  secret_id = each.value.name
  role      = each.value.role
  member    = "serviceAccount:${google_service_account.env.email}"
}

resource "google_folder_iam_member" "env" {
  for_each = {
    for k, v in local.iam_roles : k => v
    if v.type == "folder"
  }

  folder = each.value.name
  role   = each.value.role
  member = "serviceAccount:${google_service_account.env.email}"
}

resource "google_service_account_iam_binding" "env" {
  for_each = {
    for k, v in local.iam_roles : k => v
    if v.type == "impersonation"
  }

  service_account_id = "projects/${each.value.project}/serviceAccounts/${each.value.name}@${each.value.project}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = ["serviceAccount:${google_service_account.env.email}"]
}

output "email" {
  value = google_service_account.env.email
}

