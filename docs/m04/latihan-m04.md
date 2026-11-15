# Latihan 4.1 — Kunci dan riwayat state

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m04.json` (setelah Bagian E, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 04**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri. Ganti 12 digit ID akun dengan `<akun>` saat menyalin.

## 1. Dua terminal, satu state

Ringkasan plan di terminal 3 (`tofu apply -var="retensi_versi_hari=45"`, belum dijawab):

```text

```

Pesan galat `tofu plan` di terminal 4 (lengkap dengan `Lock Info`):

```text

```

Isi prefix `m04/` di bucket state selagi kunci dipegang (`list-objects-v2`):

```text

```

Isi prefix `m04/` setelah terminal 3 dijawab `no`, dan hasil `tofu plan` di terminal 4 sesudahnya:

```text

```

## 2. Riwayat state

Daftar versi di prefix `m04/` (`list-object-versions`; boleh dipangkas, sebutkan jumlahnya):

```text

```

| Hal | Isi |
|---|---|
| Jumlah versi `m04/data.tfstate` | |
| Jumlah versi dan *delete marker* `m04/data.tfstate.tflock` | |
| `serial`, `lineage` (8 karakter), jumlah `resources` dari `tofu state pull` | |

Mengapa `serial` berbeda dengan jumlah versi state:

## 3. Folder lain, state yang sama

| Perintah di folder klon | Ringkasan hasil |
|---|---|
| `tofu init -backend-config=backend.hcl` | |
| `tofu plan` | |
| `tofu plan -var="versi=4.0.0"` | |

Folder `koma-infra-salinan` sudah dihapus: ya / belum

## 4. Penjelasan

Apa yang akan terjadi pada state bila kedua operasi dibiarkan berjalan bersamaan tanpa kunci:

Kapan `tofu force-unlock` sah dipakai, apa yang harus dipastikan lebih dulu, dan apa risikonya bila dugaan Anda keliru:

Mengapa `backend.hcl` dan `kasus.tfvars` di-commit, sedangkan `terraform.tfvars` dan state tidak; kaitkan dengan plan `-var="versi=4.0.0"` di butir 3 dan Morris (2025, hlm. 354):

## 5. Bukti

- Potret 3 (setelah Bagian D) pada (WIB):
- Potret 4 (bersih) pada (WIB), `bersih_akhir`:
- `tofu plan` di terminal 3 setelah butir 1 (`No changes`, retensi tetap 30 hari?):
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m04.json` setelah Bagian E:
