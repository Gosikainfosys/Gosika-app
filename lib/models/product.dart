class Product {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? shortDescription;
  final String? sku;
  final double price;
  final double? compareAtPrice;
  final String? image;
  final List<String> images;
  final List<ProductVariant> variants;
  final double ratingAvg;
  final int ratingCount;
  final bool isFeatured;
  final String status;
  final String stockStatus;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.shortDescription,
    this.sku,
    required this.price,
    this.compareAtPrice,
    this.image,
    required this.images,
    required this.variants,
    required this.ratingAvg,
    required this.ratingCount,
    required this.isFeatured,
    required this.status,
    required this.stockStatus,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    final rawImages = json['images'];
    if (rawImages is List) {
      for (var e in rawImages) {
        if (e is String) {
          parsedImages.add(e);
        } else if (e is Map) {
          final url = e['url']?.toString() ?? e['image']?.toString();
          if (url != null && url.isNotEmpty) parsedImages.add(url);
        }
      }
    }

    final primaryImg = json['primary_image']?['url']?.toString() ?? json['image']?.toString();
    if (primaryImg != null && primaryImg.isNotEmpty && !parsedImages.contains(primaryImg)) {
      parsedImages.insert(0, primaryImg);
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Product',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      shortDescription: json['short_description']?.toString(),
      sku: json['sku']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      compareAtPrice: json['compare_at_price'] != null
          ? double.tryParse(json['compare_at_price'].toString())
          : null,
      image: primaryImg ?? (parsedImages.isNotEmpty ? parsedImages.first : null),
      images: parsedImages,
      variants: (json['variants'] as List?)
              ?.map((e) => ProductVariant.fromJson(e is Map ? Map<String, dynamic>.from(e) : {}))
              .toList() ??
          [],
      ratingAvg: double.tryParse(json['rating_avg']?.toString() ?? '0') ?? 0.0,
      ratingCount: json['rating_count'] is int ? json['rating_count'] : int.tryParse(json['rating_count']?.toString() ?? '0') ?? 0,
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true || json['is_featured'] == '1',
      status: json['status']?.toString() ?? 'active',
      stockStatus: json['stock_status']?.toString() ?? 'in_stock',
    );
  }
}

class ProductVariant {
  final String id;
  final String? name;
  final double price;
  final String? sku;
  final Map<String, String> attributes;

  ProductVariant({
    required this.id,
    this.name,
    required this.price,
    this.sku,
    required this.attributes,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      sku: json['sku']?.toString(),
      attributes: (json['attributes'] is Map)
          ? Map<String, String>.from((json['attributes'] as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
          : {},
    );
  }
}

class Category {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String? image;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.image,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString() ?? json['icon_url']?.toString(),
      image: json['image_url']?.toString() ?? json['image']?.toString(),
    );
  }
}

class Banner {
  final String id;
  final String? title;
  final String? description;
  final String imageUrl;
  final String? link;
  final String? linkType;
  final String? linkId;
  final int? position;

  Banner({
    required this.id,
    this.title,
    this.description,
    required this.imageUrl,
    this.link,
    this.linkType,
    this.linkId,
    this.position,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: (json['image'] ?? json['image_url'] ?? json['imageUrl'] ?? '').toString(),
      link: json['link'] as String?,
      linkType: json['link_type'] as String?,
      linkId: json['link_id']?.toString(),
      position: json['position'] is int
          ? json['position']
          : int.tryParse(json['position']?.toString() ?? ''),
    );
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final PaginationMeta meta;

  PaginatedResponse({required this.data, required this.meta});
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] ?? json;
    return PaginationMeta(
      currentPage: pagination['current_page'] ?? 1,
      lastPage: pagination['last_page'] ?? 1,
      perPage: pagination['per_page'] ?? 20,
      total: pagination['total'] ?? 0,
    );
  }
}
