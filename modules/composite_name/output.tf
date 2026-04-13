output "result" {
  value = join(var.separator, [
    for k, v in var.components : substr(v.value, 0, local.component_length[k])
  ])
}

output "components" {
  value = [
    for k, v in var.components :
    substr(v.value, 0, local.component_length[k])
  ]
}
