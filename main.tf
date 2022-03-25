# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "tf-az-resources"
  location = "Australia East"
}

