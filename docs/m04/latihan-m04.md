# Latihan 4.1 — Kunci dan riwayat state

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | `k01` |
| Kasus | k01 Klinik Sehat Lampung |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m04.json` (setelah Bagian E, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 04**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri. Ganti 12 digit ID akun dengan `<akun>` saat menyalin.

## 1. Dua terminal, satu state

Ringkasan plan di terminal 3 (`tofu apply -var="retensi_versi_hari=45"`, belum dijawab):

```text
  # aws_s3_bucket_lifecycle_configuration.arsip will be updated in-place
      ~ noncurrent_version_expiration {
          ~ noncurrent_days = 30 -> 45
        }
Plan: 0 to add, 1 to change, 0 to destroy.
  Enter a value:
```

Pesan galat `tofu plan` di terminal 4 (lengkap dengan `Lock Info`):

```text
│ Error: Error acquiring the state lock
│ Error message: operation error S3: PutObject, https response error
│ StatusCode: 412, RequestID: RMAY2DR6WGPPFM8C, HostID: …,
│ api error PreconditionFailed: At least one of the pre-conditions you
│ specified did not hold
│ Lock Info:
│   ID:        23da6a72-e071-3540-ff6d-c79f890c4f08
│   Path:      koma-123450039-tfstate-<akun>/m04/data.tfstate
│   Operation: OperationTypeApply
│   Who:       angels@MacBook-Air-Feby.local
│   Version:   1.13.5
│   Created:   2026-11-15 15:11:52.679382 +0000 UTC
```

Isi prefix `m04/` di bucket state selagi kunci dipegang (`list-objects-v2`):

```text
m04/data.tfstate        19948   2026-11-15T15:10:23+00:00
m04/data.tfstate.tflock 247     2026-11-15T15:11:53+00:00
```

Isi prefix `m04/` setelah terminal 3 dijawab `no`, dan hasil `tofu plan` di terminal 4 sesudahnya:

```text
Terminal 3:
  Enter a value: no
Apply cancelled.
Releasing state lock. This may take a few moments...

Terminal 4 (tofu plan):
No changes. Your infrastructure matches the configuration.
Releasing state lock. This may take a few moments...

(prefix m04/ kembali hanya berisi m04/data.tfstate; .tflock sudah dihapus saat kunci dilepas)
```

## 2. Riwayat state

Daftar versi di prefix `m04/` (`list-object-versions`; boleh dipangkas, sebutkan jumlahnya):

```text
{
  "state": 16,
  "tflock": 26,
  "penanda_hapus": 26,
  "terbaru": ["2026-11-15T15:10:23+00:00"]
}
(daftar lengkap dipangkas: m04/data.tfstate ×16, IsLatest True pada 2026-11-15T15:10:23Z;
 m04/data.tfstate.tflock ×26 semuanya noncurrent; delete marker .tflock ×26)
```

| Hal | Isi |
|---|---|
| Jumlah versi `m04/data.tfstate` | 16 |
| Jumlah versi dan *delete marker* `m04/data.tfstate.tflock` | 26 dan 26 |
| `serial`, `lineage` (8 karakter), jumlah `resources` dari `tofu state pull` | 20, `7d809b71`, 12 (3 data source + 9 resource) |

Mengapa `serial` berbeda dengan jumlah versi state: `serial` (20) dihitung sejak state lahir di disk lokal pada B.3, termasuk tulisan sewaktu apply pertama, destroy, dan apply ulang karena server sempat mendapat IP publik, sedangkan S3 baru menyimpan tulisan sejak migrasi di B.4 (16 versi). Satu operasi juga tidak selalu satu tulisan: apply yang panjang dapat menyimpan state beberapa kali, dan dua apply yang gagal karena kredensial kedaluwarsa menulis state lewat `tofu state push errored.tfstate`. Setiap operasi berkunci meninggalkan satu versi `.tflock` dan satu *delete marker* karena bucket state berversi, sedangkan plan yang ditolak di terminal 4 tidak meninggalkan apa pun karena penulisannya gagal.

## 3. Folder lain, state yang sama

| Perintah di folder klon | Ringkasan hasil |
|---|---|
| `tofu init -backend-config=backend.hcl` | `Successfully configured the backend "s3"!` tanpa pertanyaan migrasi (tidak ada state lokal); provider `hashicorp/aws v6.73.0` dipasang sesuai `.terraform.lock.hcl` |
| `tofu plan` | `No changes. Your infrastructure matches the configuration.` (mengenali `i-0881493f07b107c54`, `vol-0dc22177bf89c8b7f`, dan bucket arsip) |
| `tofu plan -var="versi=4.0.0"` | `Plan: 2 to add, 1 to change, 2 to destroy.` (server db dan attachment diganti, laporan 4.1.0 → 4.0.0); tidak di-apply |

Folder `koma-infra-salinan` sudah dihapus: ya

## 4. Penjelasan

Apa yang akan terjadi pada state bila kedua operasi dibiarkan berjalan bersamaan tanpa kunci: kedua terminal membaca state dengan `serial` yang sama, lalu masing-masing menulis state baru setelah mengubah AWS. Yang menulis belakangan menimpa yang lebih dulu, sehingga state kehilangan catatan perubahan yang sudah benar-benar terjadi di AWS; plan berikutnya dapat ingin membuat ulang resource yang sudah ada atau tidak lagi mengenali resource yang sudah diganti (Hafner, 2025, hlm. 153). Kunci mencegahnya lewat *conditional write*: `.tflock` hanya dapat ditulis bila belum ada, dan penulis kedua ditolak S3 dengan `412 PreconditionFailed`.

Kapan `tofu force-unlock` sah dipakai, apa yang harus dipastikan lebih dulu, dan apa risikonya bila dugaan Anda keliru: hanya untuk kunci yang tertinggal dari proses yang pasti sudah berhenti. Saya mengalaminya dua kali di sesi ini: apply terhenti karena kredensial kedaluwarsa (`ExpiredToken`), state tertulis ke `errored.tfstate`, dan kunci tidak terlepas. Sebelum `force-unlock` saya memastikan dari `Lock Info` bahwa `Who` adalah laptop saya sendiri, `Operation` adalah apply yang baru gagal, `Created` cocok dengan jam saya menjawab `yes`, dan tidak ada terminal lain yang menjalankan tofu. Setelah itu saya `tofu state push errored.tfstate` sebelum apply lagi. Bila dugaan keliru, misalnya kunci milik rekan yang sedang apply, dua proses kembali dapat menulis state bergantian dan hasilnya sama dengan tanpa kunci; versi state lama di bucket berversi masih bisa dipulihkan, tetapi resource ganda di AWS harus dibereskan manual. Di butir 1 latihan ini `force-unlock` tidak dipakai, karena kuncinya milik proses yang masih hidup di terminal 3.

Mengapa `backend.hcl` dan `kasus.tfvars` di-commit, sedangkan `terraform.tfvars` dan state tidak; kaitkan dengan plan `-var="versi=4.0.0"` di butir 3 dan Morris (2025, hlm. 354): `backend.hcl` hanya berisi alamat state (bucket, key, region), bukan rahasia dan bukan state; dengan berkas itu klon di folder lain langsung menemukan state yang sama dan plan-nya `No changes`. Kunci hanya mencegah dua operasi bersamaan, bukan dua folder yang menerapkan nilai berbeda bergantian: plan `-var="versi=4.0.0"` dari klon langsung ingin mengganti server kembali (Morris, 2025, hlm. 354). Karena itu nilai yang disepakati kelompok ditulis di `kasus.tfvars` dan di-commit agar sama di setiap folder. `terraform.tfvars` berisi identitas pribadi dan nilai sesi sehingga tidak di-commit, sedangkan state memuat seluruh atribut infrastruktur termasuk isi objek laporan, sehingga tempatnya di bucket state yang aksesnya dibatasi, bukan di repo.

## 5. Bukti

- Potret 3 (setelah Bagian D) pada (WIB): tidak terambil, `koma cek m04` → `verifier menolak (403): Forbidden` (15 Nov 2026)
- Potret 4 (bersih) pada (WIB), `bersih_akhir`:
- `tofu plan` di terminal 3 setelah butir 1 (`No changes`, retensi tetap 30 hari?): `No changes`, retensi tetap 30 hari
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m04.json` setelah Bagian E:
