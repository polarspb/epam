variable "generated_key_name" {
  type        = string
  default     = "epam"
  description = "Key-pair generated by Terraform"
}
variable "name" {
  default = "admin"
}

# variable "common-tags" {
#   description = "Common Tags to apply to all resources"
#   type = map
#   default = {
#       Owner = "Ilya Polishchuk"
#       Project = "Epam"
#       Environment = "Dev"
#   }
# }
