output "server_public_ip" {
  description = "LLM server public IP"
  value       = oci_core_instance.server.public_ip
}

output "server_private_ip" {
  description = "LLM server private IP"
  value       = oci_core_instance.server.private_ip
}

output "open_ports" {
  description = "TCP ingress allowed by the server security list"
  value = concat(
    [{ description = "SSH", source = var.ssh_source_cidr, port = 22 }],
    var.ingress_rules
  )
}

output "ssh_command" {
  description = "SSH command for the Ubuntu instance"
  value       = "ssh ubuntu@${oci_core_instance.server.public_ip}"
}
