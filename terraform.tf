terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.99.0"
    }
  }
}


locals {
  resource_group = "app-grp"
  location = "West Europe"
}

provider "azurerm" {
  subscription_id = "d548075b-f815-4e8e-99e6-1234e39c5708"
  client_id       = "acfa94e2-b1c9-4a53-b9b1-0472b862f9e7"
  client_secret   = "oqB8Q~xhuD8aDmAyEoImLkLhhCEjcauDgxSAZbN3"
  tenant_id       = "6800b1a8-d991-4b23-97f0-417c721ea803"
  features {}
}

resource "azurerm_resource_group" "app_grp" {
  name     = local.resource_group
  location = local.location
}

resource "azurerm_virtual_network" "app-network" {
  name                = "app-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.app_grp.name
  address_space       = ["10.0.0.0/16"]
  depends_on = [ 
    azurerm_resource_group.app_grp
   ]

}

resource "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  resource_group_name  = local.resource_group
  virtual_network_name = azurerm_virtual_network.app-network.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [ 
    azurerm_virtual_network.app-network
   ]
}

resource "azurerm_network_interface" "app_interface" {
  name                = "app-interface"
  location            = local.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.app_public_ip.id
  }
  depends_on = [ 
    azurerm_virtual_network.app-network,
    azurerm_public_ip.app_public_ip,
    azurerm_subnet.SubnetA
   ]
}

resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "appvm"
  resource_group_name = local.resource_group
  location            = local.location
  size                = "Standard_B2s"
  admin_username      = "demousr"
  admin_password      = "Azure@123"
  disable_password_authentication = false
  availability_set_id = azurerm_availability_set.app_set.id
  network_interface_ids = [
    azurerm_network_interface.app_interface.id,
  ]
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  
  user_data = base64encode(templatefile("setup.sh.tpl", {
    REPO = var.REPO
    TOKEN = var.TOKEN
  }))

  depends_on = [ 
    azurerm_network_interface.app_interface,
    azurerm_availability_set.app_set,
    azurerm_resource_group.app_grp
  ]
}

resource "azurerm_public_ip" "app_public_ip" {
  name                = "app-public-ip"
  resource_group_name = local.resource_group
  location            = local.location
  allocation_method   = "Static"
  depends_on = [ 
    azurerm_resource_group.app_grp
   ]
}


resource "azurerm_availability_set" "app_set" {
  name                = "app-set"
  location            = local.location
  resource_group_name = local.resource_group
  platform_fault_domain_count = 3
  platform_update_domain_count = 3
  depends_on = [ 
    azurerm_resource_group.app_grp
   ]
  }


resource "azurerm_network_security_group" "app_nsg" {
  name                = "acceptanceTestSecurityGroup1"
  location            = local.location
  resource_group_name = local.resource_group
  security_rule {
    name                       = "app-nsg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [ 
    azurerm_resource_group.app_grp
   ]
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.SubnetA.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
  depends_on = [ 
    azurerm_network_security_group.app_nsg
   ]
}