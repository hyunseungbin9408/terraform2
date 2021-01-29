variable "tags" {
  type = map(string)

  default = {
      environment = "vmss"
  }
}

variable "location" {
  type = string

  default = "Korea Central"
}
variable "resource_name" {
  type = string

  default = "test-vmss2"
}

variable "nic_name" {
  type = list

  default = ["nic01", "nic02"] 
}

variable "application_port" {
  type = list(number)

  default = [80, 3389]
}

variable "natrule_name" {
  type = list(string)

  default = ["http", "rdp"]
}
variable "admin_username" {
  type = string

  default = "student"
}

variable "admin_password" {
  type = string

  default = "windom12345@"
}

variable "rdprule_name" {
  type = list(string)

  default = ["RdpToVm1", "RdpToVm2"]  
}

variable "rdprule" {
  type = list(number)

  default = [50001, 50002]  
}