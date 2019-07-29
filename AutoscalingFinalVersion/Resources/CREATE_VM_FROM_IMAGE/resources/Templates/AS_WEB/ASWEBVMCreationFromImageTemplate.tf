variable "index" {
  description = "Number to create the vm_name, have to be updated after creating a VM"
  default = "XXXXXX"
}

variable "vm_hostname" {
  description = "vm_name"
  default = "QA-G-ASW"
}

variable "tagforthesnapshot" {
  description = "Tag Snapshot"
  default = "ASW_AUTOSCALE_SPRINTXXX"
}

resource "azurerm_network_interface" "network_interface_XXXXXX" {
    name = "${var.vm_hostname}${var.index}-networkint"
    location = "${var.location}"
    resource_group_name = "${data.azurerm_resource_group.resource_group.name}"

    ip_configuration{
        name = "config_autoscale"
        subnet_id = "${data.azurerm_subnet.vmSubnet.id}"
        private_ip_address_allocation = "Static"
	private_ip_address = "XXXIPXXX"
    }
}

#Virtual Machine setting
resource "azurerm_virtual_machine" "ES_DATA_VM_XXXXXX" {
    name = "${var.vm_hostname}${var.index}"
    location = "${var.location}"
    resource_group_name = "${data.azurerm_resource_group.resource_group.name}"
    vm_size = "${var.vm_size}"
    network_interface_ids = ["${azurerm_network_interface.network_interface_XXXXXX.id}"]
    
    # This means the OS Disk will be deleted when Terraform destroys the Virtual Machine
    # NOTE: This may not be optimal in all cases.
    delete_os_disk_on_termination = true
    
    storage_image_reference {
        id = "${data.azurerm_image.custom.id}"
    }

    storage_os_disk{
        name = "os_disk_XXXXXX"
        create_option = "FromImage"
        caching = "ReadWrite"
        managed_disk_type = "Standard_LRS"
    }

    os_profile{
      computer_name  = "${var.vm_hostname}${var.index}"
      admin_username = "${var.admin_user}"
      admin_password = "${var.admin_password}"

    }

    os_profile_windows_config {
        provision_vm_agent        = true
        enable_automatic_upgrades = false
    }
}
#Extension BGInfo
resource "azurerm_virtual_machine_extension" "BGInfo_XXXXXX" {
  name = "BGInfo-${azurerm_virtual_machine.ES_DATA_VM_XXXXXX.name}"
  location = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.resource_group.name}"
  virtual_machine_name = "${azurerm_virtual_machine.ES_DATA_VM_XXXXXX.name}"
  publisher            = "Microsoft.Compute"
  type                 = "BGInfo"
  type_handler_version = "2.1"
}

