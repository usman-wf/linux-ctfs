# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Generate random password
resource "random_password" "vm_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a resource group
resource "azurerm_resource_group" "ctf_rg" {
  name     = "ctf-resources"
  location = "East US"
}

# Create a virtual network
resource "azurerm_virtual_network" "ctf_network" {
  name                = "ctf-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ctf_rg.location
  resource_group_name = azurerm_resource_group.ctf_rg.name
}

# Create a subnet
resource "azurerm_subnet" "ctf_subnet" {
  name                 = "ctf-subnet"
  resource_group_name  = azurerm_resource_group.ctf_rg.name
  virtual_network_name = azurerm_virtual_network.ctf_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a public IP
resource "azurerm_public_ip" "ctf_public_ip" {
  name                = "ctf-public-ip"
  location            = azurerm_resource_group.ctf_rg.location
  resource_group_name = azurerm_resource_group.ctf_rg.name
  allocation_method   = "Dynamic"
}

# Create a network interface
resource "azurerm_network_interface" "ctf_nic" {
  name                = "ctf-nic"
  location            = azurerm_resource_group.ctf_rg.location
  resource_group_name = azurerm_resource_group.ctf_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ctf_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ctf_public_ip.id
  }
}

# Create a Linux virtual machine
resource "azurerm_linux_virtual_machine" "ctf_vm" {
  name                = "ctf-vm"
  resource_group_name = azurerm_resource_group.ctf_rg.name
  location            = azurerm_resource_group.ctf_rg.location
  size                = "Standard_B1s"  # This is a minimal size, adjust as needed
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.ctf_nic.id,
  ]

  admin_password                  = random_password.vm_password.result
  disable_password_authentication = false

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

  # Custom script extension for CTF setup
  custom_data = base64encode(templatefile("ctf_setup.sh", {
    admin_password = random_password.vm_password.result
  }))
}

# Output the public IP address
output "public_ip_address" {
  value = azurerm_public_ip.ctf_public_ip.ip_address
}

# Output the VM password
output "vm_password" {
  value     = random_password.vm_password.result
  sensitive = true
}