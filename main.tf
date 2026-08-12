terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
  required_version = ">=1.9.0"
}

provider "azurerm" {
  features {

  }
}

#To create azure resource group so that i can use that while creating other services...
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

#To create azure storage account so that i can get access to azure storage service
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "learning"
  }
}


#creating Vnet in azure (Virtual network) with defining the subnets too..
resource "azurerm_virtual_network" "vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "my-vnet"
  location            = var.location

  address_space = ["10.0.0.0/16"]

  tags = {
    environment = "learning"
  }
}

#creating the subnet inside the Vnet that just we created above ₼ŊŌŒ 
resource "azurerm_subnet" "web" {
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  name                 = "web-subnet"

  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "app" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.0.3.0/24"]
}

#creating an NSG(Network security group) and also writting inbound and outbound rules
resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location


  tags = {
    environment = "learning"
  }
}
#this will create a NSG but there are no allow rules written 
#lets add an SSH rule 
# | Port | Protocol | Purpose                |
# | ---- | -------- | ---------------------- |
# | 22   | SSH      | Linux Remote Login     |
# | 3389 | RDP      | Windows Remote Desktop |
# | 80   | HTTP     | Websites               |
# | 443  | HTTPS    | Secure Websites        |


resource "azurerm_network_security_rule" "allow_ssh" {
  network_security_group_name = azurerm_network_security_group.web_nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
  access                      = "Allow"
  name                        = "AllowSSH"
  priority                    = 100       #azure checks prioroty lower numbers are checked first (100 -1st , 200- 2nd , 300 - 3rd)
  direction                   = "Inbound" #traffic coming or going from vm
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"

  source_address_prefix      = "*" #here you are allowing all the IP addresses in fututure you can only allow your home ips or so....
  destination_address_prefix = "*"
}


#Creating a public IP (A Public IP allows the Internet to reach your VM.)
resource "azurerm_public_ip" "vm_pip" {
  name                = "vm-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  allocation_method   = "Static" # istatic : do not change when the resource is recreated , dynamic : the IP address may change if the resource is recreated.
  sku                 = "Standard"

}

# creating a network interface
resource "azurerm_network_interface" "vm_nic" {
  name                = "vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id #Connect this NIC to the Web Subnet.
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id #Associate this Public IP with the NIC.
  }
}


# #Creating an NSG does nothing by itself.
# Think of it like buying a security guard but not assigning them to a building.
# You must attach the NSG. Now every VM created in that subnet automatically follows those NSG rules.
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

#Command to create an SSH key for VM
# ssh-keygen -t rsa -b 4096 - In PowerShell


#now lets create the VM Linux vm
resource "azurerm_linux_virtual_machine" "vm" {
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = "my-linux-vm"
  size                = "Standard_D2ls_v6"

  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/azure_vm.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  #This block tells Azure which operating system to install:
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    environment = "Learning"
  }
}