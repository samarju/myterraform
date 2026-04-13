# Composite name generator

This module can be used to generate composite names
from a list of components joined in-order using
a separator string, that is of a given max length.
If any components must be shortened, each components
precedence is taken into account and only shortened
enough to fit within the given max length.

It is particularly useful to generate AWS resource
names that have rather low length limits, e.g.
ELB names or ELB target group names.

Together with random\_id it might also be useful
to generate better AWS resource names when
name\_prefix restricts remaining input space
to much for our use-cases.
