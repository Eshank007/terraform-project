terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"
    }
  }
}

####Note - We need to setup Azure Key Vault proper access policies to allow your Terraform script to access these secrets#####

provider "azurerm" {
  features {}
}

data "azurerm_key_vault_secret" "subscription_id" {
  name         = "SUBSCRIPTION_ID_SECRET_NAME"
  key_vault_id = "KEY_VAULT_ID"
}

data "azurerm_key_vault_secret" "client_id" {
  name         = "CLIENT_ID_SECRET_NAME"
  key_vault_id = "KEY_VAULT_ID"
}

data "azurerm_key_vault_secret" "client_secret" {
  name         = "CLIENT_SECRET_SECRET_NAME"
  key_vault_id = "KEY_VAULT_ID"
}

data "azurerm_key_vault_secret" "tenant_id" {
  name         = "TENANT_ID_SECRET_NAME"
  key_vault_id = "KEY_VAULT_ID"
}


data "azurerm_key_vault_secret" "admin_username" {
  name         = "admin-username-secret"
  key_vault_id = "KEY_VAULT_ID"
}

data "azurerm_key_vault_secret" "admin_password" {
  name         = "admin-password-secret"
  key_vault_id = "KEY_VAULT_ID"
}


resource "azurerm_resource_group" "exp1" {
  name     = "myrg"
  location = "east-us"
}

resource "azurerm_virtual_network" "exp2" {
  name                = "myvnet"
  location            = "east-us"
  resource_group_name = "myrg"
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "mysubnet"
    address_prefix = "10.0.1.0/24"
  }
}

resource "azurerm_network_security_group" "exp3" {
  name                = "mynsg"
  location            = "east-us"
  resource_group_name = "myrg"

  security_rule {
    name                       = "myssh"
    priority                   = 101
    protocol                   = "Tcp"
    direction                  = "Inbound"
    access                     = "Allow"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
  }
}

resource "azurerm_public_ip" "exp4" {
  name                = "mypip"
  location            = "east-us"
  resource_group_name = "myrg"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "exp5" {
  name                = "mynic"
  location            = "east-us"
  resource_group_name = "myrg"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "mysubnetid"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "public_ip_id"
  }
}

resource "azurerm_linux_virtual_machine" "exp6" {
  name                = "myvm"
  location            = "east-us"
  resource_group_name = "myrg"
  size                = "Standard_F2"
  admin_username      = data.azurerm_key_vault_secret.admin_username.value
  admin_password      = data.azurerm_key_vault_secret.admin_password.value



  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "myhostname"
    admin_username = data.azurerm_key_vault_secret.admin_username.value
  }

  os_profile_linux_config {
    disable_password_authentication = true
  }
}

####Note - Create SSH Key Pair on local system and Store the SSH Private Key in Azure Key Vault with the correct valut access policy so that terrafrom can use it###

  provisioner "remote-exec" "exp7" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3",
      "chmod 700 get_helm.sh",
      "sudo ./get_helm.sh",
    ]
  }

  connection {
    type        = "ssh"
    host        = VM_public_ip_address ##refer to Exp5##
    user        = data.azurerm_key_vault_secret.admin_username.value
    private_key = data.azurerm_key_vault_secret.ssh_private_key.value
  }
}
