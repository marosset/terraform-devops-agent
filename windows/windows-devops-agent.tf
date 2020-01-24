variable "location" {
  type    = string
  default = "westus2"
}

variable "username" {
  type    = string
  default = "azureuser"
}

variable "password" {
  type = string
}

variable "devOpsUrl" {
  type = string
}

variable "pat" {
  type = string
}

variable "pool" {
  type = string
}

variable "machine_name" {
  type = string
}

provider "azurerm" {
}

resource "azurerm_resource_group" "rg" {
  name     = "devops-agents-tf"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name          = "devops-agents-vnet"
  address_space = ["172.16.3.0/24"]

  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "devops-agents-tf-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = "172.16.3.0/24"
}

resource "azurerm_public_ip" "public-ip" {
  name                = "public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                      = "nic"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name
  network_security_group_id = azurerm_network_security_group.nsg.id

  ip_configuration {
    name                          = "ip-config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-ip.id
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = var.computer_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_D2s_v3"

  storage_os_disk {
    name              = "osDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "datacenter-core-1909-with-containers-smalldisk"
    version   = "latest"
  }

  os_profile {
    computer_name  = var.machine_name
    admin_username = var.username
    admin_password = var.password

  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }
}

resource "azurerm_virtual_machine_extension" "ext" {
  name                 = "devops-agent-init"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_machine_name = azurerm_virtual_machine.vm.name
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
  {
    "fileUris": [
      "https://raw.githubusercontent.com/marosset/terraform-devops-agent/master/windows/devops_agent_install.ps1"
    ]
  }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File devops_agent_install.ps1 -devOpsUrl ${var.devOpsUrl} -pat ${var.pat} -pool ${var.pool} -windowsUserName ${var.username} -windowsPassword ${var.password}"
  }
  PROTECTED_SETTINGS
}
