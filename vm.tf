# Create network interface
resource "azurerm_network_interface" "main" {
  name                = "tf-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create SSH key
resource "tls_private_key" "tf_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# output key for reuse with virtual machines
output "tls_private_key" {
  value     = tls_private_key.tf_ssh.private_key_pem
  sensitive = true
}

# export private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.tf_ssh.private_key_pem
  filename        = "tf_ssh.pem"
  file_permission = "0600"
}

# create virtual machine scale set
resource "azurerm_linux_virtual_machine_scale_set" "example" {
  name                = "vmss"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard_B2s"
  instances           = 1
  admin_username      = "adminuser"

  user_data = filebase64("apache.sh")

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.tf_ssh.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = azurerm_subnet.backend.id
      #load_balancer_backend_address_pool_ids = [azurerm_application_gateway.network.backend_address_pool[0].id]
      primary = true
    }
 }

}