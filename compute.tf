locals {
  availability_domains = data.oci_identity_availability_domains.ads.availability_domains
  availability_domain  = try(local.availability_domains[var.ad_index].name, null)
  base_image_id        = data.oci_core_images.ubuntu_arm.images[0].id
}

resource "oci_core_instance" "server" {
  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = "${var.project_name}-server"
  shape               = "VM.Standard.A1.Flex"

  freeform_tags = {
    workload = "llm"
    billing  = "always-free-only"
  }

  shape_config {
    ocpus         = var.server_ocpu
    memory_in_gbs = var.server_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = local.base_image_id
    boot_volume_size_in_gbs = var.boot_volume_size_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "${var.project_name}-server-vnic"
    hostname_label   = "llm"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init/server.yaml", {
      ingress_rules = var.ingress_rules
      ssh_cidr      = var.ssh_source_cidr
    }))
  }

  preserve_boot_volume = false

  lifecycle {
    ignore_changes = [metadata, source_details]

    precondition {
      condition     = var.ad_index < length(local.availability_domains)
      error_message = "ad_index is outside the Availability Domains available in the selected region."
    }
  }
}
