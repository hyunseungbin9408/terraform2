provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_name
  location = var.location
}

resource "random_string" "fqdn" {
    length  = 6
    special = false
    upper   = false
    number  = false
}
resource "azurerm_virtual_network" "vmss" {
    name            = "vmss-vnet"
    address_space   = [ "10.0.0.0/16" ]
    location        = var.location
    resource_group_name = var.resource_name
    tags            = var.tags
}

resource "azurerm_subnet" "vmss" {
    name                = "vmss-subnet"
    address_prefixes      = [ "10.0.1.0/24" ]
    resource_group_name = var.resource_name
    virtual_network_name = azurerm_virtual_network.vmss.name
}

resource "azurerm_public_ip" "vmss" {
    name = "vmss-public-ip"
    location = var.location
    resource_group_name = var.resource_name
    allocation_method = "Static"
    domain_name_label = random_string.fqdn.result
    tags              = var.tags
}

resource "azurerm_lb" "vmss" {
    name = "vmss-lb"
    location = var.location
    resource_group_name = var.resource_name

    frontend_ip_configuration {
      name = "PublicIPAddress"
      public_ip_address_id = azurerm_public_ip.vmss.id
    }

    tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "bepool" {
    resource_group_name = var.resource_name
    loadbalancer_id = azurerm_lb.vmss.id
    name            = "vmss-bepool"
}

resource "azurerm_lb_probe" "vmss" {
    resource_group_name = var.resource_name
    loadbalancer_id = azurerm_lb.vmss.id
    name    = "http-running-probe"
    port    = var.application_port[0]
}

resource "azurerm_lb_rule" "lbnatrule" {
    resource_group_name = var.resource_name
    loadbalancer_id     = azurerm_lb.vmss.id
    name                = var.natrule_name[0]
    protocol            = "Tcp"
    frontend_port       = var.application_port[0]
    backend_port         = var.application_port[0]
    backend_address_pool_id = azurerm_lb_backend_address_pool.bepool.id
    frontend_ip_configuration_name = "PublicIPAddress"
    probe_id = azurerm_lb_probe.vmss.id
}

resource "azurerm_lb_rule" "rdprule" {
    count = "${length(var.rdprule_name)}"

    resource_group_name = var.resource_name
    loadbalancer_id     = azurerm_lb.vmss.id
    name                = var.rdprule_name[count.index]
    protocol            = "Tcp"
    frontend_port       = var.rdprule[count.index]
    backend_port         = var.application_port[1]
    backend_address_pool_id = azurerm_lb_backend_address_pool.bepool.id
    frontend_ip_configuration_name = "PublicIPAddress"
    probe_id = azurerm_lb_probe.vmss.id
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
    name = "VmScaleSet"
    location = var.location
    resource_group_name = var.resource_name
    upgrade_policy_mode = "Manual"

    sku {
        name = "Standard_B1s"
        tier = "Standard"
        capacity = 2
    }

    storage_profile_image_reference {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2016-Datacenter"
      version   = "latest"
    }

    storage_profile_os_disk {
      name = ""
      caching = "ReadWrite"
      create_option = "FromImage"
      managed_disk_type = "Standard_LRS"
    }

    storage_profile_data_disk {
      lun = 0
      caching = "ReadWrite"
      create_option = "Empty"
      disk_size_gb = 50
    }

    os_profile {
      computer_name_prefix = "vmlab"
      admin_username  = var.admin_username
      admin_password = var.admin_password
      custom_data = file("web.conf")
    }

    network_profile {
        name = "terraformnetworkprofile"
        primary = true

        ip_configuration {
            name = "IPConfiguration"
            subnet_id = azurerm_subnet.vmss.id
            load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bepool.id]
            primary = true
        }
    }
    tags = var.tags
}