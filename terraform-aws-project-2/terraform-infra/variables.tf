variable "region" {}
variable "cidr_block" {}
variable "my_ip" {}
variable "db_password" {
  sensitive = true
}