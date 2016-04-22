variable "scratch_size" {
    description = "volume size of slurm ctrl node (exported to slaves)"
    default = "1024"
}

variable "image_id" {
    description = "UUID of node image"
    default = "7364ada7-263e-4fb0-a9f4-219ab19e0be0"
}

variable "flavor_id" {
    description = "flavor type for nodes"
    default = "2a912855-769a-43ff-b4a2-e12cef4c2e9d"
}

variable "num_slaves" {
    description = "number of slurm slave nodes"
    default = "3"
}
