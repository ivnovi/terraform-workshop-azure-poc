resource "azurerm_resource_group" "workshop_rg" {
  name     = "0_terraform-workshop"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "workshop_vnet" {
  name                = "workshop_vnet"
  resource_group_name = "${azurerm_resource_group.workshop_rg.name}"
  address_space       = ["10.1.0.0/16"]
  location            = "${var.location}"
}

resource "azurerm_subnet" "workshop_subnet_primary" {
  name                      = "workshop_subnet_primary"
  resource_group_name       = "${azurerm_resource_group.workshop_rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.workshop_vnet.name}"
  address_prefix            = "10.1.1.0/24"
  network_security_group_id = "${azurerm_network_security_group.workshop_security.id}"
}

resource "azurerm_subnet" "workshop_subnet_secondary" {
  name                      = "workshop_subnet_secondary"
  resource_group_name       = "${azurerm_resource_group.workshop_rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.workshop_vnet.name}"
  address_prefix            = "10.1.2.0/24"
  network_security_group_id = "${azurerm_network_security_group.workshop_security.id}"
}

resource "azurerm_network_security_group" "workshop_security" {
  name                = "workshop_security"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.workshop_rg.name}"
}

resource "azurerm_network_security_rule" "www" {
  name                        = "web"
  priority                    = 1010
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "${var.devmachineip}/32"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.workshop_rg.name}"
  network_security_group_name = "${azurerm_network_security_group.workshop_security.name}"
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "ssh"
  priority                    = 1011
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "${var.devmachineip}/32"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.workshop_rg.name}"
  network_security_group_name = "${azurerm_network_security_group.workshop_security.name}"
}

# elasticsearch
resource "azurerm_network_security_rule" "elasticsearch1" {
  name                        = "elasticsearch1"
  priority                    = 1012
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "9200"
  source_address_prefix       = "${var.devmachineip}/32"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.workshop_rg.name}"
  network_security_group_name = "${azurerm_network_security_group.workshop_security.name}"
}

resource "azurerm_network_security_rule" "elasticsearch2" {
  name                        = "elasticsearch2"
  priority                    = 1013
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "9300"
  source_address_prefix       = "${var.devmachineip}/32"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.workshop_rg.name}"
  network_security_group_name = "${azurerm_network_security_group.workshop_security.name}"
}

resource "azurerm_network_security_rule" "elasticsearch3" {
  name                        = "elasticsearch3"
  priority                    = 1014
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5601"
  source_address_prefix       = "${var.devmachineip}/32"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.workshop_rg.name}"
  network_security_group_name = "${azurerm_network_security_group.workshop_security.name}"
}


