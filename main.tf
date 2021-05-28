variable "config" {
  type = map(any)
}

locals {
  # Transform inputs into a HCL map that can be used in `for_each` loops
  gsa_iam_membership = {
    for rule in flatten([
      for key, val in var.config : [
        for tpl in val : [
          for role in tpl.roles :
          {
            gsa  = key
            type = tpl.type
            name = tpl.name
            role = role
          }
        ]
      ]
    ]) : "${rule.gsa}-${rule.name}-${rule.role}" => rule
  }
}

resource "google_service_account" "env" {
  for_each   = var.config
  account_id = each.key
}

resource "google_project_iam_member" "env" {
  for_each = {
    for k, v in local.gsa_iam_membership : k => v
    if v.type == "project"
  }

  project = each.value.name
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.env[each.value.gsa].email}"
}

resource "google_storage_bucket_iam_member" "env" {
  for_each = {
    for k, v in local.gsa_iam_membership : k => v
    if v.type == "bucket"
  }

  bucket = each.value.name
  role   = each.value.role
  member = "serviceAccount:${google_service_account.env[each.value.gsa].email}"
}

output "emails" {
  value = {
    for gsa in google_service_account.env : gsa.account_id => gsa.email
  }
}

