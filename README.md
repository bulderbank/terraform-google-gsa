# terraform-google-gsa

This module will create service accounts and IAM roles, accross any number of Google Cloud projects, based on the inputs passed through `var.config`.

The inputs must be structured correctly:

```
# Example:

module "gsa" {
  source = <path to this module>
  config = yamldecode(<<-EOT
    gsa-cnrm:
      - type: project
        name: bulder-sandbox-dev
        roles:
          - roles/iam.workloadIdentityUser
          - roles/iam.serviceAccountAdmin
          - roles/resourcemanager.projectIamAdmin
      - type: project
        name: terraform-admin-303613
        roles:
          - roles/resourcemanager.projectIamAdmin
          - roles/secretmanager.admin
      - type: project
        name: bulder-sandbox-shared
        roles:
          - roles/resourcemanager.projectIamAdmin
          - roles/secretmanager.admin

    gsa-gke:
      - type: project
        name: bulder-sandbox-dev
        roles:
          - roles/storage.objectViewer
          - roles/logging.logWriter
          - roles/monitoring.metricWriter
          - roles/cloudtrace.agent
          - roles/compute.instanceAdmin.v1
          - roles/iam.serviceAccountUser
          - roles/stackdriver.resourceMetadata.writer
      - type: bucket
        name: eu.artifacts.bulder-sandbox-shared.appspot.com
        roles:
          - roles/storage.objectViewer
  EOT
  )
}
```

