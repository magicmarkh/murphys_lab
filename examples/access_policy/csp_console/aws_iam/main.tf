locals {
  # Calculate today at 00:00:00 if from_time is not provided
  default_from_time = formatdate("YYYY-MM-DD'T'00:00:00", timestamp())

  # Calculate one week from today at the current time if to_time is not provided
  default_to_time = formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), "168h"))

  # Use provided values or fall back to calculated defaults
  from_time = var.from_time != null ? var.from_time : local.default_from_time
  to_time   = var.to_time != null ? var.to_time : local.default_to_time
}

resource "idsec_policy_cloud_access" "example_policy" {
  metadata = {
    name        = var.policy_name
    description = var.policy_description,
    status = {
      status = "Active"
    },
    time_frame = {
      from_time = local.from_time
      to_time = local.to_time
    }
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
    aws_account_targets = var.aws_account_targets
  }
}