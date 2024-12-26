variable "RESOURCE_GROUP_NAME" {
  type        = string
  description = "Name of resouce group"
}

variable "LOCATION" {
  type        = string
  default     = "Southeast Asia"
  description = "Location of resource group"
}

variable "VIRTUAL_NETWORK_NAME" {
  type        = string
  description = "Name of virtual network"
}

variable "SUBSCRIPTION_ID" {
  type        = string
  description = "Subscription id of azure account. command: 'az login' and 'az account show' -> parameter name: 'id'"
}

variable "VARNISH_NETWORK_SECURITY_GROUP" {
  type        = string
  description = "Name of varnish security group"
}

variable "MAGENTO_NETWORK_SECURITY_GROUP" {
  type        = string
  description = "Name of magento security group"
}

variable "SUBNET" {
  type        = string
  description = "Name of subnet"
}

variable "NATGATEWAY_PUBLIC_IP" {
  type        = string
  description = "Name of natgatway public IP"
}

variable "NAT_GATEWAY" {
  type        = string
  description = "Name of nat gateway"
}

variable "VM_NAMES" {
  type        = list(string)
  description = "Name of the virual machines"
}

variable "STORAGE_DATA_DISK_SIZE" {
  type        = map(any)
  description = "Storage data disk size"
}

variable "MYSQL_SERVER_NAME" {
  type        = string
  description = "Mysql server name"
}

variable "MYSQL_ADMIN_USERNAME" {
  type        = string
  description = "Mysql admin username"
}

variable "MYSQL_ADMIN_PASSWORD" {
  type        = string
  description = "Mysql admin password"
}

variable "LB_PUBLIC_IP" {
  type        = string
  description = "public IP of load balancer"
}

variable "LB_NAME" {
  type        = string
  description = "Name of load balancer"
}

variable "LB_BACKEND_ADDRESS_POOL" {
  type        = string
  description = "Manages a Load Balancer Backend Address Pool"
}

variable "LB_PROB" {
  type        = string
  description = "Manages a LoadBalancer Probe Resource"
}

variable "LB_RULE" {
  type        = string
  description = "Manages a LoadBalancer Probe Resource"
}

variable "NATGATEWAY_PUBLIC_IP_PREFIX" {
  type        = string
  description = "Manages a Public IP Prefix"
}

variable "SSH_KEY" {
  type = string
  description = "SSH key for server login"
}
