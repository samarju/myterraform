variable "separator" {
  type        = string
  description = "The separator between components"
  default     = "-"
  nullable    = false
}

variable "max_length" {
  type        = number
  description = "Maximum length of output string"
  nullable    = false
}

variable "components" {
  type = list(object({
    value             = string
    min_prefix_length = number
    precedence        = number
  }))

  description = <<-EOT
    List of components to concatenate, separated by var.separator.
    Value is the full length component string, min_prefix_length the
    minimal length of the prefix to keep. The precedence parameter
    defines the order in which components will be shortened until the
    ouput string is shorter than var.max_length.
    Components with higher precedence will be shortened first.

    NOTICE: The sequence of all given precedence values must start at zero and
            be consecutive without jumps, i.e. 0, 1, 2, 3, 4, etc.
  EOT

  nullable = false
}
