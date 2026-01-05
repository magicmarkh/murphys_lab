resource "idsec_policy_cloud_access" "example_policy" {
  metadata = {
    name        = var.policy_name
    description = var.policy_description,
    status = {
      status = "Active"
    },
    policy_entitlement = {
      target_category = "Cloud console",
      location_type   = var.location_type
    },
    policy_tags = ["test_policy", "example"],
    time_zone   = var.time_zone
  }
  principals = var.principals
  conditions = {
    access_window = {
      days_of_the_week = var.access_window_days
      from_hour        = var.access_window_from_hour
      to_hour          = var.access_window_to_hour
    }
    max_session_duration = var.max_session_duration
  }
  targets = {
    aws_organization_targets = var.aws_organization_targets
  }
}