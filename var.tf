variable "frontend_port" {
  type = list(number)
  default = [50001, 50002]
}

variable "Network_interface" {
  type = list
  default = ["nic01","nic02"]
}

variable "nsg_name" {
  type = list
  default = ["nsg01", "nsg02"]  
}

variable "vm_name" {
    type = list
    default = ["Winvm01", "Winvm02"]
}

variable "LBNR_name" {
    type = list
    default = ["lbNR01", "lbNR02"]  
}