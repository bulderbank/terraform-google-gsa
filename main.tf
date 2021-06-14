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


  project   = each.value.project
  secret_id = each.value.name
  role      = each.value.role
  member    = "serviceAccount:${google_service_account.env.email}"
}

