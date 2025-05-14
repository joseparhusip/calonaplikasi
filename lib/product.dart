class Product {
  final int idProduct;
  final String namaProduct;
  final String deskripsi;
  final String gambarproduct;
  final int stok;
  final int harga;
  final int ulasan;
  final int stars;
  final String namaToko;

  Product({
    required this.idProduct,
    required this.namaProduct,
    required this.deskripsi,
    required this.gambarproduct,
    required this.stok,
    required this.harga,
    required this.ulasan,
    required this.stars,
    required this.namaToko,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      idProduct: json['id_product'] ?? 0,
      namaProduct: json['nama_product'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      gambarproduct: json['gambarproduct'] ?? '',
      stok: json['stok'] ?? 0,
      harga: json['harga'] ?? 0,
      ulasan: json['ulasan'] ?? 0,
      stars: json['stars'] ?? 0,
      namaToko: json['nama_toko'] ?? 'Unknown Store',
    );
  }
}
