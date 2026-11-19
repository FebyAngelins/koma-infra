# Enkripsi sisi klien: OpenTofu mengenkripsi state dan berkas plan sebelum ditulis, sehingga
# pembaca bucket state (atau berkas *.tfplan) hanya melihat teks sandi. Passphrase datang dari
# environment TF_VAR_kunci_state, tidak pernah dari berkas di repo.
terraform {
  encryption {
    key_provider "pbkdf2" "kunci" {
      passphrase = var.kunci_state
    }

    method "aes_gcm" "utama" {
      keys = key_provider.pbkdf2.kunci
    }

    state {
      method   = method.aes_gcm.utama
      enforced = true
    }

    plan {
      method   = method.aes_gcm.utama
      enforced = true
    }
  }
}
