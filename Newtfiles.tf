terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 1.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  client_id       = "4007f70b-451c-40ae-8b9d-602354c01964"
  client_secret   = "Liz8Q~sZ3B9oy1EKQz8i-vTGETVHpxiJj4Wx0cNL"
  tenant_id       = "b41b72d0-4e9f-4c26-8a69-f949f367c91d"
  subscription_id = "297c4e9f-28e6-4778-ad07-a716ff83d66c"
}

locals {
  resource_group = "Netrg2"
  location       = "eastus"
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "expn1" {
  name     = local.resource_group
  location = local.location
}

resource "azurerm_virtual_network" "expn2" {
  name                = "myvnet2"
  location            = local.location
  resource_group_name = local.resource_group
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "expn8" {
  name                 = "subnetA"
  resource_group_name  = local.resource_group
  virtual_network_name = azurerm_virtual_network.expn2.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on           = [azurerm_virtual_network.expn2]
}

resource "azurerm_network_interface" "expn3" {
  name                = "myvmnic"
  location            = local.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.expn8.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.expn6.id
  }
  depends_on = [azurerm_virtual_network.expn2, azurerm_public_ip.expn6, azurerm_subnet.expn8]
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "expn5" {
  name                  = "myappvm"
  admin_username        = "demouser"
  admin_password        = azurerm_key_vault_secret.expn14.value
  location              = local.location
  resource_group_name   = local.resource_group
  availability_set_id   = azurerm_availability_set.expn7.id
  network_interface_ids = [azurerm_network_interface.expn3.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter"
    version   = "latest"
  }
  depends_on = [azurerm_network_interface.expn3, azurerm_availability_set.expn7, azurerm_key_vault_secret.expn14]
}

resource "azurerm_public_ip" "expn6" {
  name                = "vm-pip"
  resource_group_name = local.resource_group
  location            = local.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_availability_set" "expn7" {
  name                          = "myvmsas"
  resource_group_name           = local.resource_group
  location                      = local.location
  platform_fault_domain_count   = 3
  platform_update_domain_count  = 3
}

resource "azurerm_network_security_group" "expn10" {
  name                = "mynsg"
  location            = local.location
  resource_group_name = local.resource_group

  security_rule {
    name                       = "myrdp"
    priority                   = 101
    protocol                   = "Tcp"
    direction                  = "Inbound"
    access                     = "Allow"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
  }
}

resource "azurerm_subnet_network_security_group_association" "expn11" {
  subnet_id                   = azurerm_subnet.expn8.id
  network_security_group_id  = azurerm_network_security_group.expn10.id
  depends_on                 = [azurerm_network_security_group.expn10]
}

resource "azurerm_key_vault" "expn12" {
  name                        = "mykey596666"
  location                    = local.location
  resource_group_name         = local.resource_group
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    

    key_permissions = ["Get", "Update","Backup", "Delete", "List"]

    secret_permissions = ["Get", "Backup", "Delete", "Set", "List"]

    storage_permissions = ["Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "0521c9c0-03dd-4ec7-a6af-2cfe200a4b50"
    

    key_permissions = ["Get", "Update","Backup", "Delete", "List"]

    secret_permissions = ["Get", "Backup", "Delete", "Set", "List"]

    storage_permissions = ["Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"]
  }

  depends_on = [azurerm_resource_group.expn1]
}

resource "azurerm_key_vault_secret" "expn14" {
  name         = "sauce"
  value        = "Welcome@54321"
  key_vault_id = azurerm_key_vault.expn12.id
  depends_on   = [azurerm_key_vault.expn12]
}
