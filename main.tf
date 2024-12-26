# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.66.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = var.SUBSCRIPTION_ID
  features {}
}

resource "azurerm_resource_group" "petfoodProdResourceGroup" {
  name     = var.RESOURCE_GROUP_NAME
  location = var.LOCATION
}

resource "azurerm_network_security_group" "petfoodVarnishNetworkSecurityGroup" {
    name                 = var.VARNISH_NETWORK_SECURITY_GROUP
    resource_group_name  = azurerm_resource_group.petfoodProdResourceGroup.name
    location             = azurerm_resource_group.petfoodProdResourceGroup.location

    depends_on = [
        azurerm_resource_group.petfoodProdResourceGroup
    ]
}

resource "azurerm_network_security_group" "petfoodMagentoNetworkSecurityGroup" {
  name                  = var.MAGENTO_NETWORK_SECURITY_GROUP
  resource_group_name   = azurerm_resource_group.petfoodProdResourceGroup.name
  location              = azurerm_resource_group.petfoodProdResourceGroup.location

  depends_on = [
      azurerm_resource_group.petfoodProdResourceGroup
  ]
}

resource "azurerm_network_security_rule" "DenyAzureLoadBalancerInBound" {
  name                        = "DenyAzureLoadBalancer"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.petfoodMagentoNetworkSecurityGroup.resource_group_name
  network_security_group_name = azurerm_network_security_group.petfoodMagentoNetworkSecurityGroup.name
  
  depends_on = [
    azurerm_network_security_group.petfoodMagentoNetworkSecurityGroup
  ]
}

resource "azurerm_virtual_network" "petfoodProdVirtualNetwork" {
  name                = var.VIRTUAL_NETWORK_NAME
  resource_group_name = azurerm_resource_group.petfoodProdResourceGroup.name
  location            = azurerm_resource_group.petfoodProdResourceGroup.location
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["8.8.8.8", "8.8.4.4"]

  depends_on = [
    azurerm_resource_group.petfoodProdResourceGroup
  ]
}

resource "azurerm_subnet" "petfoodSubnet" {
  name                 = var.SUBNET
  resource_group_name  = azurerm_resource_group.petfoodProdResourceGroup.name
  virtual_network_name = azurerm_virtual_network.petfoodProdVirtualNetwork.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [
    azurerm_virtual_network.petfoodProdVirtualNetwork,
    azurerm_resource_group.petfoodProdResourceGroup
  ]
}

resource "azurerm_public_ip" "petfoodNatGatewayPublicIP" {
  name                = var.NATGATEWAY_PUBLIC_IP
  location            = azurerm_resource_group.petfoodProdResourceGroup.location
  resource_group_name = azurerm_resource_group.petfoodProdResourceGroup.name
  allocation_method   = "Static"
  ip_version          = "IPv4"
  sku                 = "Standard"

  depends_on = [
    azurerm_resource_group.petfoodProdResourceGroup
  ]

  timeouts {
    create = "1m"
  }
}

resource "azurerm_public_ip_prefix" "petfoodPublicIPPrefix" {
  name                = var.NATGATEWAY_PUBLIC_IP_PREFIX
  location            = azurerm_resource_group.petfoodProdResourceGroup.location
  resource_group_name = azurerm_resource_group.petfoodProdResourceGroup.name
  prefix_length       = 31
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "petfoodNatGateway" {
  name                = var.NAT_GATEWAY
  location            = azurerm_resource_group.petfoodProdResourceGroup.location
  resource_group_name = azurerm_resource_group.petfoodProdResourceGroup.name

  depends_on = [
    azurerm_resource_group.petfoodProdResourceGroup
  ]
}

resource "azurerm_nat_gateway_public_ip_association" "petfoodNatGatewayPublicIPAssoc" {
  nat_gateway_id       = azurerm_nat_gateway.petfoodNatGateway.id
  public_ip_address_id = azurerm_public_ip.petfoodNatGatewayPublicIP.id

  depends_on = [
    azurerm_nat_gateway.petfoodNatGateway,
    azurerm_public_ip.petfoodNatGatewayPublicIP
  ]
}

resource "azurerm_subnet_nat_gateway_association" "petfoodSubnetNatGatewayAssociation" {
  subnet_id      = azurerm_subnet.petfoodSubnet.id
  nat_gateway_id = azurerm_nat_gateway.petfoodNatGateway.id

  depends_on = [
    azurerm_subnet.petfoodSubnet,
    azurerm_nat_gateway.petfoodNatGateway
  ]
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "petfoodNatGatewayPublicIpPrefixAssoc" {
  nat_gateway_id      = azurerm_nat_gateway.petfoodNatGateway.id
  public_ip_prefix_id = azurerm_public_ip_prefix.petfoodPublicIPPrefix.id

  depends_on = [
    azurerm_nat_gateway.petfoodNatGateway,
    azurerm_public_ip.petfoodNatGatewayPublicIP
  ]

  timeouts {
    create = "2m"
  }
}

resource "azurerm_network_interface" "petfoodNetworkInterface" {
  for_each            = toset(var.VM_NAMES)
  name                = each.value
  location            = var.LOCATION
  resource_group_name = azurerm_resource_group.petfoodProdResourceGroup.name

  ip_configuration {
    name                          = "ipconfig-${each.value}"
    subnet_id                     = azurerm_subnet.petfoodSubnet.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_subnet.petfoodSubnet,
    azurerm_resource_group.petfoodProdResourceGroup
  ]
}

resource "azurerm_network_interface_security_group_association" "petfoodVarnishNetworkInterfaceSecirityGroupAssoc" {
  network_interface_id      = azurerm_network_interface.petfoodNetworkInterface[var.VM_NAMES[1]].id
  network_security_group_id = azurerm_network_security_group.petfoodVarnishNetworkSecurityGroup.id
}

resource "azurerm_network_interface_security_group_association" "petfoodMagentoNetworkInterfaceSecirityGroupAssoc" {
  network_interface_id      = azurerm_network_interface.petfoodNetworkInterface[var.VM_NAMES[0]].id
  network_security_group_id = azurerm_network_security_group.petfoodMagentoNetworkSecurityGroup.id
}

resource "azurerm_virtual_machine" "petfoodVirtualMachine" {
  for_each                         = toset(var.VM_NAMES)
  name                             = each.value
  resource_group_name              = azurerm_resource_group.petfoodProdResourceGroup.name
  location                         = var.LOCATION
  network_interface_ids            = [azurerm_network_interface.petfoodNetworkInterface[each.key].id]
  vm_size                          = "Standard_F2s_v2"
  delete_data_disks_on_termination = true
  delete_os_disk_on_termination    = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${each.value}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name          = "${each.value}-data-disk"
    disk_size_gb  = var.STORAGE_DATA_DISK_SIZE[each.value]
    create_option = "empty"
    lun           = 0
  }

  os_profile {
    computer_name  = each.value
    admin_username = "petfoodadmin"
    admin_password = "Admin@123"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        path     = "/home/petfoodadmin/.ssh/authorized_keys"
        key_data = var.SSH_KEY
    }
  }
}

resource "azurerm_mysql_server" "petfoodMysqlServer" {
  name                = var.MYSQL_SERVER_NAME
  location            = azurerm_resource_group.petfoodProdResourceGroup.location
  resource_group_name = azurerm_resource_group.petfoodProdResourceGroup.name

  administrator_login          = var.MYSQL_ADMIN_USERNAME
  administrator_login_password = var.MYSQL_ADMIN_PASSWORD

  sku_name   = "B_Gen5_1"
  storage_mb = 21504
  version    = "8.0"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = false

  depends_on = [
    azurerm_resource_group.petfoodProdResourceGroup
  ]
}

resource "azurerm_public_ip" "petfoodLBPublicIP" {
  name                = var.LB_PUBLIC_IP
  location            = azurerm_resource_group.petfoodProdResourceGroup.location
  resource_group_name = azurerm_resource_group.petfoodProdResourceGroup.name
  allocation_method   = "Static"
  ip_version          = "IPv4"
  sku                 = "Standard"

  depends_on = [
    azurerm_resource_group.petfoodProdResourceGroup
  ]
}

resource "azurerm_lb" "petfoodLB" {
  name                = var.LB_NAME
  location            = azurerm_resource_group.petfoodProdResourceGroup.location
  resource_group_name = azurerm_resource_group.petfoodProdResourceGroup.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = var.LB_PUBLIC_IP
    public_ip_address_id = azurerm_public_ip.petfoodLBPublicIP.id
  }

  depends_on = [
    azurerm_public_ip.petfoodLBPublicIP,
    azurerm_resource_group.petfoodProdResourceGroup
  ]
}

resource "azurerm_lb_backend_address_pool" "petfoodLBBackendAddPool" {
  loadbalancer_id = azurerm_lb.petfoodLB.id
  name            = var.LB_BACKEND_ADDRESS_POOL

  depends_on = [
    azurerm_lb.petfoodLB
  ]
}

resource "azurerm_lb_probe" "qmartLBProb" {
  resource_group_name = azurerm_resource_group.petfoodProdResourceGroup.name
  loadbalancer_id     = azurerm_lb.petfoodLB.id
  name                = var.LB_PROB
  port                = 80
  protocol            = "Tcp"

  depends_on = [
    azurerm_resource_group.petfoodProdResourceGroup,
    azurerm_lb.petfoodLB
  ]
}

resource "azurerm_lb_rule" "example" {
  resource_group_name            = azurerm_resource_group.petfoodProdResourceGroup.name
  loadbalancer_id                = azurerm_lb.petfoodLB.id
  name                           = var.LB_RULE
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = var.LB_PUBLIC_IP
}
