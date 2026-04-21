<h1 align="center">🎙️ Studio PodCast</h1>

<p align="center">
  Centralized Podcast Studio Reservation & Monitoring 🎧
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/2d5aac2a-7e77-4dd8-b31c-6d1c3660627e" width="80%" />
</p>

<p align="center">
   ───────────── 🎙️ ───────────── 
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Framework-blue?style=for-the-badge">
  <img src="https://img.shields.io/badge/Supabase-Backend-3ecf8e?style=for-the-badge">
  <img src="https://img.shields.io/badge/CRUD-Implemented-orange?style=for-the-badge">
  <img src="https://img.shields.io/badge/Multi%20Page-Navigation-purple?style=for-the-badge">
</p>

<p align="center">
   ───────────── 🎙️ ───────────── 
</p>
</p>

---

## Kelompok Ayam Jago

| No | Nama                         | NIM        |
|----|------------------------------|-----------|
| 1  | IRVANI CANLUSTY MISSA        | 2409116019 |
| 2  | DENY CANDRA KASUMA           | 2409116024 |
| 3  | ZELSYA RIZQITA RAHMADHINI    | 2409116022 |
| 4  | NURHIDAYAH                   | 2409116002 |

---

## Mitra

<h2 align="center">Mitra</h2>

<p align="center">
</p>


<p align="center">
  <img src="https://github.com/user-attachments/assets/0ed9cb08-139f-441f-a7e8-e1d64f682d7b" width="40%">
</p>


<p align="center">
  <strong>Fakultas Ekonomi & Bisnis</strong><br><br>
  Sebagai pengelola dan penyedia fasilitas Studio Podcast,<br>
  serta mendukung operasional dan implementasi sistem reservasi.
</p>


---

## Deskripsi Aplikasi

Aplikasi Studio PodCast merupakan aplikasi mobile yang digunakan untuk melakukan reservasi dan monitoring penggunaan studio podcast secara digital. Melalui aplikasi ini, pengguna dapat mendaftar dan login sebagai mahasiswa atau admin, kemudian melakukan pemesanan studio, melihat jadwal, serta mengelola reservasi seperti mengubah atau membatalkan peminjaman.

Admin memiliki akses untuk mengelola seluruh reservasi yang masuk, termasuk menyetujui atau menolak permintaan peminjaman, serta memantau status penggunaan studio. Selain itu, aplikasi ini juga menyediakan fitur riwayat peminjaman sehingga seluruh aktivitas penggunaan studio dapat tercatat dengan baik.

---

## Permasalahan

Proses peminjaman Studio Podcast FEB saat ini masih dilakukan secara manual melalui chat WhatsApp tanpa adanya sistem yang terintegrasi. Hal ini menyebabkan proses pengelolaan menjadi kurang efisien dan tidak terstruktur. Selain itu, kondisi ini menimbulkan beberapa kendala seperti tidak adanya pencatatan data yang terpusat, ketergantungan pada satu pihak sebagai penanggung jawab, serta tidak tersedianya sistem monitoring yang jelas untuk mengetahui status penggunaan studio dan riwayat peminjaman.

| No | Permasalahan                     | Penjelasan |
|----|----------------------------------|-----------|
| 1  | Proses Manual                    | Peminjaman masih dilakukan melalui WhatsApp |
| 2  | Tidak Ada Database Terpusat      | Data peminjaman tidak tersimpan dalam sistem terintegrasi |
| 3  | Bentrok Jadwal                  | Tidak ada sistem yang mengatur jadwal sehingga berpotensi terjadi tabrakan |
| 4  | Tidak Ada Riwayat               | Riwayat penggunaan studio tidak tercatat |
| 5  | Sulit Monitoring                | Tidak dapat memantau status studio secara jelas |

---

## Solusi

Untuk mengatasi permasalahan tersebut, kami mengusulkan pembuatan aplikasi reservasi dan monitoring Studio Podcast FEB berbasis mobile. Aplikasi ini dirancang untuk mempermudah proses peminjaman, menyediakan pencatatan yang terpusat, serta memungkinkan monitoring penggunaan studio secara real-time.

| No | Solusi                     | Deskripsi |
|----|--------------------------|----------|
| 1  | Digitalisasi Reservasi    | Mengubah proses peminjaman dari manual menjadi sistem digital berbasis aplikasi |
| 2  | Database Terpusat         | Menyimpan seluruh data reservasi dalam satu sistem yang terintegrasi |
| 3  | Sistem Approval           | Menyediakan fitur persetujuan reservasi oleh admin |
| 4  | Monitoring Penggunaan     | Memungkinkan pemantauan status studio secara real-time |
| 5  | Riwayat Terstruktur       | Menyediakan data histori peminjaman yang tersimpan dengan rapi |


---

## Fitur Aplikasi

| No | Fitur            | Deskripsi |
|----|------------------|----------|
| 1  | Splash Screen    | Menampilkan tampilan awal berupa logo aplikasi sebagai identitas dan pembuka sebelum masuk ke halaman berikutnya. |
| 2  | Login Page       | Halaman untuk masuk ke aplikasi menggunakan email dan password yang telah terdaftar. |
| 3  | Register Page    | Halaman untuk pengguna baru dalam membuat akun agar dapat mengakses aplikasi. |
| 4  | Home Page        | Menampilkan informasi utama serta navigasi ke fitur dalam aplikasi. |
| 5  | Reservasi Page   | Digunakan untuk menambah, melihat, mengedit, dan menghapus data reservasi studio. |
| 6  | Admin Page       | Halaman khusus admin untuk menyetujui atau menolak permintaan reservasi. |
| 7  | Profile Page     | Menampilkan dan mengelola data pribadi pengguna. |
| 8  | Riwayat Reservasi| Menampilkan histori atau catatan penggunaan studio oleh pengguna. |

--- 

## Integrasi Supabase

Supabase digunakan sebagai backend dalam aplikasi ini untuk menangani proses autentikasi dan pengelolaan data. Fitur authentication dimanfaatkan untuk kebutuhan login dan register pengguna, sedangkan database digunakan untuk menyimpan serta mengelola data reservasi melalui operasi CRUD (Create, Read, Update, Delete).


### Contoh tabel 

| Field       | Keterangan                |
|-------------|--------------------------|
| id          | ID reservasi             |
| user_id     | ID pengguna              |
| tanggal     | Tanggal peminjaman       |
| waktu       | Waktu penggunaan         |
| status      | Status reservasi         |
| keterangan  | Catatan tambahan         |

--- 

## Widget yang Digunakan

### MaterialApp

```
MaterialApp(
  debugShowCheckedModeBanner: false,
  home: SplashPage(),
)
```

### Scaffold

```dart
Scaffold(
  appBar: AppBar(title: Text("Home")),
)
```

### TextField

```dart
TextField(
  controller: emailController,
)
```

### ElevatedButton

```dart
ElevatedButton(
  onPressed: login,
  child: Text("Login"),
)
```

### ListView

```dart
ListView.builder(
  itemCount: data.length,
  itemBuilder: (context, index) {
    return Text(data[index].nama);
  },
)
```

### Navigator

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => HomePage()),
);
```

### FutureBuilder

```dart
FutureBuilder(
  future: getData(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    return Text("Data Loaded");
  },
)
```

## State Management

Aplikasi ini menggunakan metode **setState** untuk mengelola perubahan state pada widget. Metode ini digunakan untuk memperbarui tampilan secara langsung ketika terjadi perubahan data, seperti saat menampilkan hasil reservasi atau perubahan input dari pengguna.

**🔀 Navigation**

- **Navigator.push** → untuk berpindah ke halaman baru  
- **Navigator.pushReplacement** → untuk mengganti halaman saat ini tanpa bisa kembali  

**🔐 Environment Configuration**

Aplikasi menggunakan file `.env` untuk menyimpan konfigurasi penting seperti API Key agar lebih aman. Menggunakan package **flutter_dotenv** untuk membaca file `.env`, sehingga API Key tidak ditulis langsung di dalam kode.

- SUPABASE_URL=your_url  
- SUPABASE_ANON_KEY=your_key  

--- 

## Struktur Folder

> <img width="222" height="313" alt="image" src="https://github.com/user-attachments/assets/9d19150b-ab9f-4998-a2fd-0fc8e2483eff" />

--- 

## Package yang Digunakan

| Flutter | Supabase |
|--------|----------|
| <img src="https://img.icons8.com/color/96/flutter.png" width="70"/> | <img src="https://seeklogo.com/images/S/supabase-logo-DCC676FFE2-seeklogo.com.png" width="70"/> |

--- 

## Alur Aplikasi

--- 

## 👨‍💼 Menu Admin

### 1. Login Admin

   <img width="700" height="1571" alt="WhatsApp Image 2026-04-21 at 00 18 50" src="https://github.com/user-attachments/assets/831ed547-8bca-4cda-bb19-33a52dcbcca0" />

Admin membuka aplikasi dan langsung diarahkan ke halaman login, kemudian memasukkan email dan kata sandi yang sudah terdaftar, setelah itu menekan tombol “Masuk Sekarang”, lalu sistem akan memverifikasi data ke Supabase dan jika berhasil, admin akan diarahkan ke halaman utama/admin untuk mengelola reservasi.

--- 

### 2. Beranda Admin

> <img width="1080" height="2333" alt="image" src="https://github.com/user-attachments/assets/98d73562-ac7d-4778-9712-84282b7ee04e" />

Setelah admin berhasil login, sistem akan menampilkan halaman beranda admin yang berisi informasi akun serta menu utama, kemudian admin dapat mengakses fitur monitoring untuk melihat dan mengelola data reservasi yang masuk.

---

### 3. Monitoring Reservasi

> <img width="1080" height="2336" alt="image" src="https://github.com/user-attachments/assets/870811e8-eb78-4ece-8590-84e30a0818b1" />

Saat admin membuka menu monitoring, sistem menampilkan halaman riwayat peminjaman yang berisi daftar seluruh data reservasi, sehingga admin dapat melihat detail pengajuan yang masuk secara terpusat.

--- 

### 4. Filter Data

> <img width="1080" height="2331" alt="image" src="https://github.com/user-attachments/assets/e79a8cf9-3400-4e86-8ce1-303793778c9d" />

Pada halaman riwayat peminjaman, admin dapat menggunakan fitur filter berdasarkan status (seperti semua, pending, approved, atau rejected) untuk menyaring dan melihat data reservasi sesuai kebutuhan.

--- 

### 5. Pencarian Data

> <img width="1080" height="2340" alt="image" src="https://github.com/user-attachments/assets/cfab4750-f72d-4395-b481-dc176ba7a435" />

Pada halaman riwayat, admin dapat menggunakan fitur pencarian untuk menemukan data reservasi tertentu berdasarkan nama atau kata kunci sehingga memudahkan pencarian data secara cepat.

---

### 6. Approve / Reject Reservasi

> <img width="1080" height="2339" alt="image" src="https://github.com/user-attachments/assets/4eb85190-a1dd-4a50-b21b-b2c0b76a9f50" />

Pada halaman riwayat, admin dapat melihat detail reservasi dan mengubah status pengajuan dari pending menjadi approved atau rejected sebagai proses persetujuan.

---

### 7. Monitoring Status


> <img width="1080" height="2337" alt="image" src="https://github.com/user-attachments/assets/da7d80cd-2bd8-4638-8a97-e2680b3ca4eb" />

Pada halaman filter status, admin dapat memilih kategori seperti approved atau rejected untuk menampilkan daftar reservasi sesuai statusnya, sehingga memudahkan dalam memantau hasil persetujuan serta mengecek data pengajuan yang sudah diproses.

---

### 8. Profil & Logout

> <img width="718" height="1600" alt="WhatsApp Image 2026-04-20 at 23 05 46" src="https://github.com/user-attachments/assets/d419a216-010f-45f0-94c2-e875693e3572" />

Pada halaman profil, admin dapat melihat dan mengubah informasi akun seperti foto, nama, email, dan deskripsi, kemudian menyimpan perubahan untuk memperbarui data, serta dapat melakukan logout untuk keluar dari aplikasi dan kembali ke halaman login.

---

## 👤 Menu User

### 1. Splash Screen

> <img width="706" height="1516" alt="WhatsApp Image 2026-04-21 at 13 58 37" src="https://github.com/user-attachments/assets/4a2ce888-52bd-40db-8d9b-d74ddf4f3f5c" />


Saat aplikasi dibuka, pengguna akan melihat halaman splash screen yang menampilkan logo sebagai identitas aplikasi dan memberikan kesan awal, kemudian setelah beberapa saat sistem akan secara otomatis mengarahkan pengguna ke halaman login untuk melanjutkan penggunaan aplikasi.

---

### 2. Login

> <img width="1080" height="2343" alt="image" src="https://github.com/user-attachments/assets/a446e305-745c-4985-b6f5-d2cbb323eeb4" />


Setelah melewati splash screen, pengguna akan diarahkan ke halaman login untuk memasukkan email dan kata sandi yang sudah terdaftar, lalu menekan tombol masuk agar dapat mengakses fitur utama dalam aplikasi.

---

### 3. Register

> <img width="1080" height="2343" alt="image" src="https://github.com/user-attachments/assets/796f6c24-7b6b-4bad-bd51-258877c72e83" />

Jika pengguna belum memiliki akun, pengguna dapat masuk ke halaman register dengan mengisi data seperti nama lengkap, email, kata sandi, dan konfirmasi kata sandi, kemudian menekan tombol daftar untuk membuat akun baru agar bisa login ke dalam aplikasi.

---

### 4. Beranda User

> <img width="706" height="1528" alt="image" src="https://github.com/user-attachments/assets/c1122fa0-fe1a-4a69-80c4-6f5b6aa3cea0" />


Setelah berhasil login, pengguna akan diarahkan ke halaman beranda yang menampilkan informasi akun serta menu utama, kemudian pengguna dapat memilih fitur seperti reservasi studio untuk melanjutkan proses penggunaan aplikasi.

---

### 5. Halaman Reservasi

> <img width="706" height="1523" alt="image" src="https://github.com/user-attachments/assets/7f8b43e5-2e5b-46eb-bcb3-0bd6e7def17d" />


Saat pengguna masuk ke menu reservasi, sistem akan menampilkan halaman jadwal studio yang berisi daftar reservasi yang tersedia, kemudian pengguna dapat melihat, mencari, atau memfilter jadwal sesuai kebutuhan sebelum melakukan pemesanan.

---

### 6. Tambah Reservasi

> <img width="1080" height="2338" alt="image" src="https://github.com/user-attachments/assets/ae46a008-2af8-4c44-a44a-e9f71e431f10" />


Untuk membuat reservasi baru, pengguna dapat menekan tombol tambah pada halaman jadwal, lalu sistem akan menampilkan form pengajuan yang harus diisi seperti nama peminjam, nomor telepon, tanggal, jam mulai, jam selesai, dan deskripsi kegiatan sebelum data dikirim ke sistem.

---

### 7. Validasi Data

> <img width="1080" height="2340" alt="image" src="https://github.com/user-attachments/assets/c9551c8b-ce29-4f3b-b184-e40ff3118ee4" />


Sebelum data reservasi dikirim, sistem akan melakukan validasi terhadap input yang dimasukkan oleh pengguna, seperti memastikan waktu mulai dan selesai sesuai, sehingga jika terdapat kesalahan maka pengguna harus memperbaikinya terlebih dahulu sebelum melanjutkan proses pengajuan.

---

### 8. Status Pending

> <img width="1079" height="2339" alt="image" src="https://github.com/user-attachments/assets/874f028f-0a54-42f2-87b9-9dc31b598fbd" />


Setelah data reservasi berhasil dikirim, sistem akan menampilkan notifikasi bahwa pengajuan berhasil dan statusnya menjadi pending, kemudian data tersebut akan masuk ke daftar reservasi untuk menunggu persetujuan dari admin.

---

### 9. Daftar Reservasi


> <img width="1080" height="2343" alt="image" src="https://github.com/user-attachments/assets/009242ec-de72-4c0f-a7cd-f9b41a5a79b3" />


Fitur pencarian pada halaman Jadwal Studio digunakan untuk mencari jadwal berdasarkan tanggal, hari, atau bulan. Saat pengguna memasukkan kata kunci, aplikasi akan memfilter dan menampilkan jadwal yang sesuai. Jika tidak ada data yang cocok, maka hasil tidak ditampilkan.

---

### 10. Profil User

> <img width="1080" height="2336" alt="image" src="https://github.com/user-attachments/assets/e57c9894-2eb2-46c3-b15b-71d85facf9d5" />

Pada halaman profil, pengguna dapat melihat dan mengubah data seperti foto, nama, email, dan deskripsi, lalu menyimpan perubahan. Pengguna juga dapat logout untuk keluar dari akun dan kembali ke halaman login.


--- 
