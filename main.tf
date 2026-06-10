terraform {
  required_version = ">= 1.9"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }
}

provider "oci" {
  auth                = "APIKey"
  config_file_profile = var.oci_auth_mode == "profile" ? var.config_file_profile : null
  tenancy_ocid        = var.oci_auth_mode == "direct" ? var.tenancy_ocid : null
  user_ocid           = var.oci_auth_mode == "direct" ? var.user_ocid : null
  fingerprint         = var.oci_auth_mode == "direct" ? var.fingerprint : null
  private_key_path    = var.oci_auth_mode == "direct" ? var.private_key_path : null
  region              = var.region
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# Latest Ubuntu 24.04 ARM image in the selected region.
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}
