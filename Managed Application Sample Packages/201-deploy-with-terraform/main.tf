# Configure the Microsoft Azure Provider
provider "azurerm" {
    version         = "=2.0.0"
    subscription_id = var.azure_subscription_id
    #client_id       = var.service_principal_id
    #client_secret   = var.service_principal_secret
    #tenant_id       = var.azure_ad_tenant_id 
    skip_provider_registration = true
    features{}
}
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "eastus"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}



resource "azurerm_subnet" "example" {
  count               = var.subnet_count
  name                = "example-subnet-${count.index}"
  virtual_network_name = azurerm_virtual_network.example.name
  resource_group_name = azurerm_resource_group.example.name
   address_prefixes    = [cidrsubnet(azurerm_virtual_network.example.address_space[0], 8, count.index + 1)]
}

data "azurerm_resource_group" "example" {
  name = azurerm_resource_group.example.name
}

variable "subnet_count" {
  type = number
  default = 3
}

resource "azurerm_route_table" "example" {
  count               = var.subnet_count
  name                = "example-route-table-${count.index + 1}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  route {
    name                   = "example"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.3.4"
  }
}

resource "azurerm_subnet_route_table_association" "example" {
  count                    = var.subnet_count
  subnet_id                = azurerm_subnet.example[count.index].id
  route_table_id           = azurerm_route_table.example[count.index].id
}


/*
data "azurerm_region" "example" {
  name = data.azurerm_resource_group.example.location
}*/


# Create storage account for boot diagnostics
resource "azurerm_storage_account" "diag" {
    name                        = var.stg_account_name
    resource_group_name         = var.resource_group_name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    account_kind                = "BlobStorage"

    tags = {
        environment = "${var.base_name} Managed App"
    }
}

