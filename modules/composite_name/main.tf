locals {
  num_separators   = length(var.components) - 1
  separator_length = local.num_separators * length(var.separator)

  # Length of all components with lower precedence 
  length_before = [
    for u in var.components :
    try(sum([
      for v in var.components : length(v.value)
      if v.precedence < u.precedence
    ]), 0)
  ]

  # Length of all shortended components with higher precedence 
  length_after = [
    for u in var.components :
    try(sum([
      for v in var.components : min(length(v.value), v.min_prefix_length)
      if v.precedence > u.precedence
    ]), 0)
  ]

  must_shorten_component = [
    for k, v in var.components :
    length(v.value) > v.min_prefix_length && (local.length_before[k] + length(v.value) + local.length_after[k] + local.separator_length) > var.max_length
  ]

  # Length the output string exceeds var.max_len by, if all all components with
  # higher precedence are shortened. Used to determine acutal prefix length. 
  excess_length = [
    for k, v in var.components :
    local.must_shorten_component[k] ? (
      # must_shorten_component == true => len > max_len => length - max_len > 0
      (local.length_before[k] + length(v.value) + local.length_after[k] + local.separator_length) - var.max_length
    ) : -1
  ]

  # The length of each component 
  component_length = [
    for k, v in var.components : local.must_shorten_component[k] ? (
      max(length(v.value) - local.excess_length[k], v.min_prefix_length)
    ) : length(v.value)
  ]
}
