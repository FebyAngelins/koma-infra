# State di S3 (bucket dari stack m00-state). Nilainya di backend.hcl:
#   tofu init -backend-config=backend.hcl
# use_lockfile = true membuat berkas kunci <key>.tflock di bucket selama plan/apply.
terraform {
  backend "s3" {}
}
