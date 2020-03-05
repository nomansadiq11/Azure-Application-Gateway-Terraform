resource "azurerm_resource_group" "ApplicationGateway" {

    name     = "ApplicationGatewayExamplerg"
    location = "West Europe"

    tags = {
        environment = "${var.tag}"
    }
  
}



resource "azurerm_virtual_network" "vnetexample" {
  name                = "vnetexample"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.APIManagment.name}"
  address_space       = ["10.0.0.0/16"]
  
}


resource "azurerm_subnet" "AGsubnet" {

  name                 = "acsprod_AG_subnet"
  resource_group_name  = "${azurerm_resource_group.ApplicationGateway.name}"
  address_prefix       = "10.0.1.0/24"
  virtual_network_name = "${azurerm_virtual_network.vnetexample.name}"
 
  
}




resource "azurerm_public_ip" "pf_ApplicationGateway_Pub_IP" {
  name                = "agpubip"
  location            = "${azurerm_resource_group.ApplicationGateway.location}"
  resource_group_name = "${azurerm_resource_group.ApplicationGateway.name}"
  allocation_method   = "Dynamic"
}


locals {
  backend_address_pool_name_API      = "${azurerm_virtual_network.vnetexample.name}-api"
  frontend_port_name_API             = "${azurerm_virtual_network.vnetexample.name}-api-feport"
  frontend_ip_configuration_name_API = "${azurerm_virtual_network.vnetexample.name}-api-feip"
  http_setting_name_API              = "${azurerm_virtual_network.vnetexample.name}-api-htst"
  listener_name_API                  = "${azurerm_virtual_network.vnetexample.name}-api-httplstn"
  request_routing_rule_name_API      = "${azurerm_virtual_network.vnetexample.name}-api-rqrt"


  backend_address_pool_name_Web      = "${azurerm_virtual_network.vnetexample.name}-web"
  frontend_port_name_Web             = "${azurerm_virtual_network.vnetexample.name}-web-feport"
  frontend_ip_configuration_name_Web = "${azurerm_virtual_network.vnetexample.name}-web-feip"
  http_setting_name_Web              = "${azurerm_virtual_network.vnetexample.name}-web-htst"
  listener_name_Web                  = "${azurerm_virtual_network.vnetexample.name}-web-httplstn"
  request_routing_rule_name_Web      = "${azurerm_virtual_network.vnetexample.name}-web-rqrt"



}

resource "azurerm_application_gateway" "PF_ApplicationGateway" {
  name                = "ag-example"
  resource_group_name = "${azurerm_resource_group.ApplicationGateway.name}"
  location            = "${azurerm_resource_group.ApplicationGateway.location}"

  sku {
    name     = "WAF_Medium"
    tier     = "WAF"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = "${azurerm_subnet.AGsubnet.id}"
  }

  frontend_port {
    name = "${local.frontend_port_name_API}"
    port = 80
  }

  
  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name_API}"
    public_ip_address_id = "${azurerm_public_ip.pf_ApplicationGateway_Pub_IP.id}"
  }

  

  

  backend_address_pool {
  
    name = "${local.backend_address_pool_name_API}"
    ip_address_list = ["10.0.0.67"]
  }

  backend_address_pool {
  
    name = "${local.backend_address_pool_name_Web}"
    ip_address_list = ["10.0.0.68"]
  }
    


  backend_http_settings {
    name                  = "${local.http_setting_name_API}"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  backend_http_settings {
    name                  = "${local.http_setting_name_Web}"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = "${local.listener_name_API}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name_API}"
    frontend_port_name             = "${local.frontend_port_name_API}"
    protocol                       = "Http"
  }


  request_routing_rule {
    name                       = "${local.request_routing_rule_name_API}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name_API}"
    backend_address_pool_name  = "${local.backend_address_pool_name_API}"
    backend_http_settings_name = "${local.http_setting_name_API}"
  }
}