variable "oci_auth_mode" {
  description = "OCI authentication mode: profile reads ~/.oci/config, direct uses the API key variables"
  type        = string
  default     = "profile"

  validation {
    condition     = contains(["profile", "direct"], var.oci_auth_mode)
    error_message = "oci_auth_mode must be either profile or direct."
  }
}

variable "config_file_profile" {
  description = "Profile name in ~/.oci/config when oci_auth_mode is profile"
  type        = string
  default     = "DEFAULT"

  validation {
    condition     = var.oci_auth_mode != "profile" || trimspace(var.config_file_profile) != ""
    error_message = "config_file_profile cannot be empty when oci_auth_mode is profile."
  }
}

variable "tenancy_ocid" {
  description = "OCI tenancy OCID when oci_auth_mode is direct"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.oci_auth_mode == "direct" ? var.tenancy_ocid != null : var.tenancy_ocid == null
    error_message = "tenancy_ocid is required in direct mode and must be unset in profile mode."
  }
}

variable "user_ocid" {
  description = "OCI user OCID when oci_auth_mode is direct"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.oci_auth_mode == "direct" ? var.user_ocid != null : var.user_ocid == null
    error_message = "user_ocid is required in direct mode and must be unset in profile mode."
  }
}

variable "fingerprint" {
  description = "OCI API key fingerprint when oci_auth_mode is direct"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.oci_auth_mode == "direct" ? var.fingerprint != null : var.fingerprint == null
    error_message = "fingerprint is required in direct mode and must be unset in profile mode."
  }
}

variable "private_key_path" {
  description = "Path to the OCI API private key when oci_auth_mode is direct"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.oci_auth_mode == "direct" ? var.private_key_path != null : var.private_key_path == null
    error_message = "private_key_path is required in direct mode and must be unset in profile mode."
  }
}

variable "region" {
  description = "OCI region (e.g. ap-chuncheon-1)"
  type        = string
}

variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Prefix used for OCI resource display names"
  type        = string
  default     = "llm"
}

variable "ad_index" {
  description = "Availability Domain index"
  type        = number
  default     = 0

  validation {
    condition     = var.ad_index >= 0 && floor(var.ad_index) == var.ad_index
    error_message = "ad_index must be a non-negative integer."
  }
}

variable "server_ocpu" {
  description = "OCPU count for the LLM server"
  type        = number
  default     = 4

  validation {
    condition     = var.server_ocpu == 4
    error_message = "This stack is fixed to 4 OCPUs."
  }
}

variable "server_memory_gb" {
  description = "Memory in GB for the LLM server"
  type        = number
  default     = 24

  validation {
    condition     = var.server_memory_gb == 24
    error_message = "This stack is fixed to 24 GB of memory."
  }
}

variable "ssh_source_cidr" {
  description = "CIDR allowed to access SSH; use your public IP with /32"
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_source_cidr, 0))
    error_message = "ssh_source_cidr must be a valid CIDR."
  }
}

variable "ingress_rules" {
  description = "Additional TCP ports to expose. Keep empty and use an SSH tunnel by default."
  type = list(object({
    description = string
    source      = string
    port        = number
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      can(cidrhost(rule.source, 0)) &&
      rule.port >= 1 &&
      rule.port <= 65535 &&
      floor(rule.port) == rule.port &&
      rule.port != 22
    ])
    error_message = "Each ingress rule needs a valid CIDR and integer TCP port from 1 to 65535 other than 22."
  }
}

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB, fixed to the full Always Free block storage allowance"
  type        = number
  default     = 200

  validation {
    condition     = var.boot_volume_size_gb == 200
    error_message = "This stack is fixed to a single 200 GB boot volume."
  }
}
