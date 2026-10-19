# The bucket every other configuration keeps its state in. Applied once,
# first, with local state, which is then moved into the bucket itself; see
# the README.
module "state_bucket" {
  source = "../modules/state_bucket"

  bucket_name = "motifpath-terraform-state"
}
