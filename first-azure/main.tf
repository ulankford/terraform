resource "azurerm_resource_group" "TFRGexample" {
    name = "example-terraform"
    location = var.azure_location

    tags ={
        environment = "Terraform"
        CreatedBy = "Ultan"
    }
}

resource "azurerm_recovery_services_vault" "TFvault" {
    name = "Terraform-recovery-vault"
    location = var.azure_location
    resource_group_name = azurerm_resource_group.TFRGexample.name
    sku = "Standard"
}

resource "azurerm_storage_account" "TFsa" {
    name = var.azure_storage_account
    resource_group_name = azurerm_resource_group.TFRGexample.name
    location = var.azure_location
    account_tier = "Standard"
    account_replication_type = "GRS"

    tags = {
        environment = "Terraform Storage"
        CretedBy = "Ultan"
    }
}

resource "azurerm_storage_container" "example" {
    name = "terraformexamplecontainer"
    storage_account_name = azurerm_storage_account.TFsa.name
    container_access_type = "private"
}

resource "azurerm_storage_blob" "example" {
    name = "Terraform-example-blob"
    storage_container_name = azurerm_storage_container.example.name
    storage_account_name = azurerm_storage_account.TFsa.name
    type = "Block"
}

resource "azurerm_storage_share" "example" {
    name = "terraformexampleshare"
    storage_account_name = azurerm_storage_account.TFsa.name
    quota = 10
}

resource "azurerm_virtual_network" "TFNetwork" {
    name = "myVnet"
    address_space = ["10.0.0.0/16"]
    location = var.azure_location
    resource_group_name = azurerm_resource_group.TFRGexample.name
}

resource "azurerm_subnet" "TFSubnet" {
    name = "mySubnet"
    resource_group_name = azurerm_resource_group.TFRGexample.name
    virtual_network_name = azurerm_virtual_network.TFNetwork.name
    address_prefix = "10.0.1.0/24"
}

resource "azurerm_network_security_group" "TFnsg" {
    name = "TerraformNSG"
    location = var.azure_location
    resource_group_name = azurerm_resource_group.TFRGexample.name
}

resource "azurerm_network_security_rule" "TFRule1" {
    name                          = "Web80"
    priority                      = 1001
    direction                     = "Inbound"
    access                        = "Allow"
    protocol                      = "TCP"
    source_port_range             = "*"
    destination_port_range        = "80"
    source_address_prefix         = "*"
    destination_address_prefix    = "*"
    resource_group_name           = azurerm_resource_group.TFRGexample.name
    network_security_group_name   = azurerm_network_security_group.TFnsg.name
}



resource "azurerm_public_ip" "example" {
    name = "pubip1"
    location = var.azure_location
    allocation_method = "Dynamic"
    sku = "Basic"
    resource_group_name           = azurerm_resource_group.TFRGexample.name

}

resource "azurerm_network_interface" "example" {
    name = "terra-nic"
    location = var.azure_location
    resource_group_name = azurerm_resource_group.TFRGexample.name

    ip_configuration {
        name = "ipconfig1"
        subnet_id = azurerm_subnet.TFSubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.example.id 
    }

}

resource "azurerm_storage_account" "bootsa" {
    name = "tfbootdiags"
    resource_group_name = azurerm_resource_group.TFRGexample.name
    location = var.azure_location
    account_tier = "Standard"
    account_replication_type = "LRS"
}

resource "azurerm_virtual_machine" "example" {
    name = "tfexample" 
    location = var.azure_location
    resource_group_name = azurerm_resource_group.TFRGexample.name
    network_interface_ids = [azurerm_network_interface.example.id]
    vm_size = "Standard_B1s"
    delete_os_disk_on_termination = true
    delete_data_disks_on_termination = false
    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "16.04-LTS"
        version = "latest"
    }
    storage_os_disk { 
        name = "osdisk1"
        disk_size_gb = "32"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
    }
    os_profile {
        computer_name = "tfexample"
        admin_username = "vmadmin"
        admin_password = "vmPassw0rd123!"
    }
    os_profile_linux_config {
        disable_password_authentication = false
    }
    boot_diagnostics {
        enabled = "true"
        storage_uri = azurerm_storage_account.bootsa.primary_blob_endpoint
    }
}