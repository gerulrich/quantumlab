variable "vm_id" {
  type = number
}

variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "mac_address" {
  type = string
}

variable "tags" {
  type = list(string)
}

variable "cores" {
  type = number
}

variable "memory" {
  type = number
}

variable "disk_size" {
  type = number
}

variable "user_data_file_id" {
  type = string
}