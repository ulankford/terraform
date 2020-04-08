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