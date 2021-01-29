provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "window-resources2"
  location = "Korea Central"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "window-network"
  address_space       = ["10.0.0.0/8"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/16"]
}

resource "azurerm_network_interface" "nic" {
  count               = "${length(var.Network_interface)}"
  name                = "${element(var.Network_interface, count.index)}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "nsg" {
  count               = "${length(var.nsg_name)}"
  name                = "${element(var.nsg_name, count.index)}"

  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
} 

resource "azurerm_network_interface_security_group_association" "nicnsga" {
  count = "${length(var.Network_interface)}"
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg[count.index].id
}

resource "azurerm_public_ip" "PubIp" {
  name                = "PublicIPForLB"
  location            = "Korea Central"
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku = "standard"
}

resource "azurerm_lb" "ELb" {
  name                = "TestLoadBalancer"
  location            = "Korea Central"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.PubIp.id
  }
}

resource "azurerm_lb_probe" "LBP" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.ELb.id
  name                = "HTTP-probe"
  port                = 80
}

resource "azurerm_lb_backend_address_pool" "BAP" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.ELb.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_rule" "LBNR" {
  count = "${length(var.frontend_port)}"
  name                           = "${element(var.LBNR_name, count.index)}"

  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.ELb.id
  protocol                       = "Tcp"
  frontend_port                  = var.frontend_port[count.index]
  backend_port                   = 3389
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_network_interface_nat_rule_association" "example" {
  count = "${length(var.Network_interface)}"

  network_interface_id  = azurerm_network_interface.nic[count.index].id
  ip_configuration_name = "internal"
  nat_rule_id           = azurerm_lb_nat_rule.LBNR[count.index].id
}

resource "azurerm_lb_rule" "LBR" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.ELb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_id = azurerm_lb_backend_address_pool.BAP.id
}


resource "azurerm_network_interface_backend_address_pool_association" "anibap" {
  count = "${length(var.Network_interface)}"

  network_interface_id    =  azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.BAP.id
}

resource "azurerm_availability_set" "example" {
  name                = "example-aset"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  platform_fault_domain_count = 1
  platform_update_domain_count = 1

  tags = {
    environment = "Production"
  }
}

resource "azurerm_windows_virtual_machine" "WinVm" {
  count = "${length(var.Network_interface)}"

  name                = "${element(var.vm_name, count.index)}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "student"
  admin_password      = "wisdom12345@"

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
