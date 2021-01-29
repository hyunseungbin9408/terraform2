resource "azurerm_resource_group" "rg" {
  name     = "window-resources"
  location = "Korea Central"
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
