variable "subscription_id" {
  description = "Azure subscription where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
}

variable "vpn_public_ip" {
  description = "Public IP address of the VPN client to allow access to the Container App"
  type        = string
}

variable "app_name" {
  description = "Application Name"
  type        = string
}

variable "github_username" {
  type        = string
  description = "GitHub organization or username"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name"
}

variable "acr_name" {
  type        = string
  description = "Azure Container Registry name (must be globally unique, without dashes)"
}
