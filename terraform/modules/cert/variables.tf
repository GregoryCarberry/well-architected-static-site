variable "domain_name" { type = string }
variable "san_names" { type = list(string) }
variable "zone_id" { type = string }
variable "tags" { type = map(string) }
