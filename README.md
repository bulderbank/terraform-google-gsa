> Deprecated: Please use:
> - https://github.com/bulderbank/terraform-google-iam
> - https://github.com/bulderbank/terraform-google-service-account


# terraform-google-gsa

This module will create Google Service Accounts (GSA).
For convenience, it also supports defining IAM roles for GCP Projects, and GCP Storage Buckets + GCP Secret Manager secrets in any GCP Project.

The key idea behind bundling Service Account creation with common IAM resource roles, is to centralize the definition the GSA's IAM roles in one place (the place where the GSA itself is defined).
Using this module for all GSA IAM role defintions is a counter-spaghetti pattern; it isolates the IAM permissions for a given GSA to a single location within the code.

```
# Example:
locals {
  example = yamldecode(<<-EOT
    gha-k8s-deploy:
      - type: project
        name: bulder-sandbox-shared
        roles:
          - roles/cloudbuild.builds.builder
          - roles/storage.objectViewer
          - roles/viewer
      - type: project
        name: bulder-sandbox-dev
        roles:
          - roles/container.developer
      - type: bucket
        name: eu.artifacts.bulder-sandbox-shared.appspot.com
        roles:
          - roles/storage.objectAdmin
      # Example: Secret in the same project as the GSA
      - type: secret
        name: secret-number-one
        roles:
          - roles/storage.objectAdmin
      # Example: Secret in some other project
      - type: secret
        name: secret-number-two
        project: bulder-yolo-swag
        roles:
          - roles/secretmanager.objectAdmin
      # Example: Impersonate service account in other project
      - type: impersonation
        name: some-service-account
        project: different-project
        roles:
          - roles/placeholder.role # Hax to make GSA module apply the impersonation
  EOT
  )
}

module "gsa" {
  source = <path to this module>
  for_each = local.example

  account_id = each.key
  project = "some-project"
  iam_roles = each.value
}
```

