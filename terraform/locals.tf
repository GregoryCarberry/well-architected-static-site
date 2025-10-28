locals {
  common_tags = {
    Project = var.project_name
    Env     = "prod"
    Owner   = "Gregory John Carberry"
  }
}
