class ProductFilters {
  String? search;
  String? category;
  String? brand;
  List<String> priceRanges;
  double? minPrice;
  double? maxPrice;
  int? minRating;
  List<String> availability;
  String sortBy;
  double? lat;
  double? lng;
  double? radius;

  ProductFilters({
    this.search,
    this.category,
    this.brand,
    List<String>? priceRanges,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    List<String>? availability,
    this.sortBy = 'newest',
    this.lat,
    this.lng,
    this.radius,
  })  : priceRanges = priceRanges ?? [],
        availability = availability ?? [];

  ProductFilters copyWith({
    String? search,
    String? category,
    String? brand,
    List<String>? priceRanges,
    double? minPrice,
    double? maxPrice,
    int? minRating,
    List<String>? availability,
    String? sortBy,
    double? lat,
    double? lng,
    double? radius,
  }) {
    return ProductFilters(
      search: search ?? this.search,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      priceRanges: priceRanges ?? List.from(this.priceRanges),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      availability: availability ?? List.from(this.availability),
      sortBy: sortBy ?? this.sortBy,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radius: radius ?? this.radius,
    );
  }

  void reset() {
    search = null;
    category = null;
    brand = null;
    priceRanges.clear();
    minPrice = null;
    maxPrice = null;
    minRating = null;
    availability.clear();
    sortBy = 'newest';
    lat = null;
    lng = null;
    radius = null;
  }

  bool get hasActiveFilters {
    return (category != null && category!.isNotEmpty) ||
        (brand != null && brand!.isNotEmpty) ||
        priceRanges.isNotEmpty ||
        minPrice != null ||
        maxPrice != null ||
        minRating != null ||
        availability.isNotEmpty ||
        lat != null;
  }

  int get activeFilterCount {
    int count = 0;
    if (category != null && category!.isNotEmpty) count++;
    if (brand != null && brand!.isNotEmpty) count++;
    if (priceRanges.isNotEmpty) count += priceRanges.length;
    if (minPrice != null || maxPrice != null) count++;
    if (minRating != null) count++;
    if (availability.isNotEmpty) count += availability.length;
    if (lat != null) count++;
    return count;
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'sort': sortBy,
    };
    if (search != null && search!.isNotEmpty) map['search'] = search;
    if (category != null && category!.isNotEmpty) {
      map['category'] = category;
      map['category_id'] = category;
    }
    if (brand != null && brand!.isNotEmpty) {
      map['brand'] = brand;
      map['brand_id'] = brand;
    }
    if (minPrice != null) map['min_price'] = minPrice;
    if (maxPrice != null) map['max_price'] = maxPrice;
    if (minRating != null) map['min_rating'] = minRating;
    if (priceRanges.isNotEmpty) map['price_ranges[]'] = priceRanges;
    if (availability.isNotEmpty) map['availability[]'] = availability;
    if (lat != null && lng != null) {
      map['lat'] = lat;
      map['lng'] = lng;
      map['radius'] = radius ?? 10.0;
    }
    return map;
  }
}
