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
Fakultas Ekonomi & Bisnis

---

## Deskripsi Aplikasi

Aplikasi Studio PodCast merupakan aplikasi mobile yang digunakan untuk melakukan reservasi dan monitoring penggunaan studio podcast secara digital. Melalui aplikasi ini, pengguna dapat mendaftar dan login sebagai mahasiswa atau admin, kemudian melakukan pemesanan studio, melihat jadwal, serta mengelola reservasi seperti mengubah atau membatalkan peminjaman.

Admin memiliki akses untuk mengelola seluruh reservasi yang masuk, termasuk menyetujui atau menolak permintaan peminjaman, serta memantau status penggunaan studio. Selain itu, aplikasi ini juga menyediakan fitur riwayat peminjaman sehingga seluruh aktivitas penggunaan studio dapat tercatat dengan baik.

---

Aplikasi ini memungkinkan pengguna untuk:
- Login dan register akun
- Melakukan reservasi studio
- Melihat dan mengelola reservasi
- Monitoring penggunaan studio
- Melihat riwayat peminjaman

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

### 1. Login Page

Pengguna dapat login menggunakan email dan password yang terdaftar pada Supabase.

### 2. Register Page
https://github.com/PA-Ayam-Jago/PRAKTIKUM-PAB/blob/3b89ffd51ede7aefe3d6e819632c6d6ac5265f0a/IMG-20260420-WA0015.jpg

Pengguna dapat membuat akun baru dengan role (Mahasiswa/Admin).

### 3. Home Page
Menampilkan daftar reservasi studio yang tersedia serta navigasi ke fitur lainnya.

### 4. Reservasi Page
Digunakan untuk:
- Menambah reservasi
- Melihat reservasi
- Edit reservasi
- Membatalkan reservasi

### 5. Admin Page
Admin dapat:
- Menyetujui (approve) reservasi
- Menolak reservasi

### 6. Profile Page
Menampilkan data pengguna.

### 7. Riwayat Reservasi
Menampilkan histori penggunaan studio.

## Fitur CRUD

### Create
Menambahkan data reservasi ke database Supabase.

### Read
Menampilkan daftar reservasi dari database.

### Update
Mengubah data reservasi.

### Delete
Menghapus atau membatalkan reservasi.

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

Aplikasi ini menggunakan metode setState untuk mengelola perubahan state pada widget. Metode ini digunakan untuk memperbarui tampilan secara langsung ketika terjadi perubahan data, seperti saat menampilkan hasil reservasi atau perubahan input dari pengguna.

### Navigasi dalam aplikasi menggunakan Navigator dari Flutter, yaitu:

- Navigator.push → untuk berpindah ke halaman baru
  
- Navigator.pushReplacement → untuk mengganti halaman saat ini tanpa bisa kembali ke halaman sebelumnya

## Environment Configuration

Aplikasi menggunakan file .env untuk menyimpan konfigurasi penting seperti API Key agar lebih aman dan tidak ditulis langsung di dalam kode.

- SUPABASE_URL=your_url

- SUPABASE_ANON_KEY=your_key

Menggunakan package:

* flutter_dotenv

API Key tidak ditulis langsung di dalam kode.

## Struktur Folder

<img width="222" height="313" alt="image" src="https://github.com/user-attachments/assets/9d19150b-ab9f-4998-a2fd-0fc8e2483eff" />

## Package yang Digunakan

* supabase_flutter
* flutter_dotenv

## Alur Aplikasi

### 🖥️ Tampilan 1 – Splash Screen

> <img width="718" height="1600" alt="WhatsApp Image 2026-04-20 at 17 00 24" src="https://github.com/user-attachments/assets/cbb2d24c-f251-468e-b139-f56912ac7687" />

---

Halaman pertama yang muncul saat aplikasi dibuka adalah splash screen yang menampilkan identitas aplikasi Studio Podcast Fakultas Ekonomi dan Bisnis Universitas Mulawarman. Pada tampilan ini, pengguna diperkenalkan dengan branding aplikasi melalui logo mikrofon yang melambangkan aktivitas podcast. Selain sebagai pembuka, halaman ini juga berfungsi memberikan kesan awal yang profesional serta menjadi transisi sebelum pengguna masuk ke halaman utama aplikasi.

--- 


### 🔐 Tampilan 2 – Halaman Login

> <img width="718" height="1600" alt="image" src="https://github.com/user-attachments/assets/4e890430-499d-45c5-9e13-1b8c80bb1a07" />

Setelah melewati splash screen, pengguna akan diarahkan ke halaman login. Pada halaman ini, pengguna diminta untuk memasukkan email dan kata sandi untuk dapat mengakses sistem. Desain yang digunakan cukup sederhana dan fokus, sehingga memudahkan pengguna dalam melakukan proses login. Jika pengguna belum memiliki akun, tersedia opsi “Daftar” yang akan mengarahkan ke halaman registrasi. Halaman ini menjadi gerbang utama untuk memastikan bahwa hanya pengguna yang terdaftar yang dapat masuk ke dalam sistem.


### 📝 Tampilan 3 – Halaman Register

> <img width="718" height="1600" alt="image" src="https://github.com/user-attachments/assets/ad35adb4-07db-48a7-a44e-1c88b92b2f62" />

--- 

Halaman register digunakan oleh pengguna baru untuk membuat akun sebelum dapat menggunakan aplikasi. Pengguna diminta mengisi beberapa data seperti nama lengkap, email aktif, kata sandi, dan konfirmasi kata sandi. Proses ini dilengkapi dengan validasi sederhana seperti minimal panjang password agar keamanan akun tetap terjaga. Setelah berhasil mendaftar, pengguna dapat kembali ke halaman login untuk masuk ke sistem. Halaman ini berperan penting dalam menambah pengguna baru dan memastikan data pengguna tersimpan dengan baik.

--- 

