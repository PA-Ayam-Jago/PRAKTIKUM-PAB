# Proyek Akhir PAB 2026
**Kelompok AYAM JAGO**

## Anggota Kelompok
- IRVANI CANLUSTY MISSA (2409116019)
- DENY CANDRA KASUMA (2409116024)
- ZELSYA RIZQITA RAHMADHINI (2409116022)
- NURHIDAYAH (2409116002)

## Mitra
Fakultas Ekonomi & Bisnis

## Deskripsi Aplikasi

Aplikasi ini merupakan pengembangan sistem **Reservasi dan Monitoring Studio Podcast FEB** yang sebelumnya masih dilakukan secara manual melalui WhatsApp tanpa pencatatan terpusat.

Pada proyek ini, aplikasi dikembangkan menggunakan **Flutter** dengan integrasi **Supabase** sebagai backend untuk autentikasi dan database.

Aplikasi ini memungkinkan pengguna untuk:
- Login dan register akun
- Melakukan reservasi studio
- Melihat dan mengelola reservasi
- Monitoring penggunaan studio
- Melihat riwayat peminjaman

## Permasalahan

- Proses peminjaman masih manual (WhatsApp)
- Tidak ada database terpusat
- Tidak ada sistem monitoring
- Riwayat tidak tercatat
- Bergantung pada satu admin

## Solusi

Mengembangkan aplikasi mobile berbasis Flutter dengan Supabase untuk:
- Digitalisasi reservasi studio
- Penyimpanan data terpusat
- Sistem approval reservasi
- Monitoring penggunaan
- Riwayat peminjaman yang terstruktur

## Fitur Aplikasi

### 1. Login Page
Pengguna dapat login menggunakan email dan password yang terdaftar pada Supabase.

### 2. Register Page
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

## Integrasi Supabase

Digunakan untuk:
- Authentication (Login & Register)
- Database (CRUD reservasi)

Contoh tabel:
### reservasi
- id
- user_id
- tanggal
- waktu
- status
- keterangan

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

Menggunakan:

* setState

## Navigation

* Navigator.push
* Navigator.pushReplacement

## Environment Configuration

Menggunakan file `.env`:

* SUPABASE_URL=your_url
* SUPABASE_ANON_KEY=your_key

Menggunakan package:

* flutter_dotenv

API Key tidak ditulis langsung di dalam kode.

## Struktur Folder

<img width="222" height="313" alt="image" src="https://github.com/user-attachments/assets/9d19150b-ab9f-4998-a2fd-0fc8e2483eff" />

## Package yang Digunakan

* supabase_flutter
* flutter_dotenv
