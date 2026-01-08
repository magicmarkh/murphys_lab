# ===========================
# Identity User Variables
# ===========================
variable "users" {
  type = map(object({
    username     = string
    display_name = string
    email        = string
  }))
  description = "Map of existing users to manage"
}
