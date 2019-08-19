variable "location" {
 description = "The location where resources will be created"
 default = "XXXlocationXXX"
}

variable "tags" {
 description = "A map of the tags to use for the resources that are deployed"

 default = {
   environment = "TEST-XX"
   build = "testing"
 }
}

variable "resource_group_name" {
    description = "The name of the resource group in which the resources will be created"
    default     = "XXXResourceGroupXXX"
}

variable "application_port" {
   description = "The port that you want to expose to the external load balancer"
   default     = 8080
}
variable "admin_user" { #Change it
   description = "User name to use as the admin account on the VMs that will be part of the VM Scale Set"
   default     = "adminqag"
}

variable "admin_password" { #Retrieve the password from ly-pass or chef
   description = "Default password for admin account"
   default = "c4YfR_W9Z%qTray3Fv7"
}

variable "virtual_network_name" {
    description = "The name of the VNET where you are going to connect your VMs"
    default = "XXXvnetXXX"
}

variable "virtual_subnetwork_name" {
    description = "The name of the VNET where you are going to connect your VMs"
    default = "XXXvsubnetXXX"
}

variable "vm_size" {
  description = "Specifies the size of the Virtual Machine"
  default = "Standard_D4s_v3"
}

variable "custom_image_name" {
    description = "The name of the image to replicate"
    default = "IMAGE-AS-WEB"
}

#Configure the Azure Provider
provider "azurerm"{ 
    subscription_id = "98175900-bfba-44bc-a6e1-fae809468cd0"
    client_id = "b474268a-7238-4b4d-b1a8-f90b08ae167b"
    client_secret = "9ba9aa58-3f59-48f7-b1d0-e4b2e631e146"
    tenant_id = "7233645c-4cba-487e-a7fa-6df50b6a606c"
}

#Create a Resource Group or join it if existent
data "azurerm_resource_group" "resource_group" {
    name     = "${var.resource_group_name}"
}

#Virtual network data retrieve
data "azurerm_virtual_network" "virtual_network" {
    name                = "${var.virtual_network_name}"
    resource_group_name = "${data.azurerm_resource_group.resource_group.name}"
}

# we assume that this Custom Image already exists
data "azurerm_image" "custom" {
  name                = "${var.custom_image_name}"
  resource_group_name = "${var.resource_group_name}"
}

#Subnet VM
data "azurerm_subnet" "vmSubnet" {
    name = "${var.virtual_subnetwork_name}"
    virtual_network_name = "${data.azurerm_virtual_network.virtual_network.name}"
    resource_group_name = "${data.azurerm_resource_group.resource_group.name}"
}
