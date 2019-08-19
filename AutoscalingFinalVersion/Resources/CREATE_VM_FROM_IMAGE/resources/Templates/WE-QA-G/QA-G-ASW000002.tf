variable "index000002" {
  description = "Number to create the vm_name, have to be updated after creating a VM"
  default = "000002"
}

variable "vm_hostname000002" {
  description = "vm_name"
  default = "QA-G-ASW"
}

variable "tagforthesnapshot000002" {
  description = "Tag Snapshot"
  default = "ASW_AUTOSCALE_SPRINT174"
}

resource "azurerm_network_interface" "network_interface_000002" {
    name = "${var.vm_hostname000002}${var.index000002}-networkint"
    location = "${var.location}"
    resource_group_name = "${data.azurerm_resource_group.resource_group.name}"

    ip_configuration{
        name = "config_autoscale"
        subnet_id = "${data.azurerm_subnet.vmSubnet.id}"
        private_ip_address_allocation = "Static"
	private_ip_address = "10.132.4.8"
    }
}

#Virtual Machine setting
resource "azurerm_virtual_machine" "ES_DATA_VM_000002" {
    name = "${var.vm_hostname000002}${var.index000002}"
    location = "${var.location}"
    resource_group_name = "${data.azurerm_resource_group.resource_group.name}"
    vm_size = "${var.vm_size}"
    network_interface_ids = ["${azurerm_network_interface.network_interface_000002.id}"]
    
    # This means the OS Disk will be deleted when Terraform destroys the Virtual Machine
    # NOTE: This may not be optimal in all cases.
    delete_os_disk_on_termination = true
    
    storage_image_reference {
        id = "${data.azurerm_image.custom.id}"
    }

    storage_os_disk{
        name = "os_disk_000002"
        create_option = "FromImage"
        caching = "ReadWrite"
        managed_disk_type = "Standard_LRS"
    }

    os_profile{
      computer_name  = "${var.vm_hostname000002}${var.index000002}"
      admin_username = "${var.admin_user}"
      admin_password = "${var.admin_password}"

    }

    os_profile_windows_config {
        provision_vm_agent        = true
        enable_automatic_upgrades = false
    }
}
#Extension BGInfo
resource "azurerm_virtual_machine_extension" "BGInfo_000002" {
  name = "BGInfo-${azurerm_virtual_machine.ES_DATA_VM_000002.name}"
  location = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.resource_group.name}"
  virtual_machine_name = "${azurerm_virtual_machine.ES_DATA_VM_000002.name}"
  publisher            = "Microsoft.Compute"
  type                 = "BGInfo"
  type_handler_version = "2.1"
}

