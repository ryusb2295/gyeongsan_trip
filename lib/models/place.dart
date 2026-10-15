class Place {
  const Place({
    required this.id,
    required this.title,
    required this.category,
    this.address,
    this.imageUrl,
    this.contentTypeId,
    this.latitude,
    this.longitude,
    this.qualityFlags = const [],
  });

  final String id;
  final String title;
  final String category;
  final String? address;
  final String? imageUrl;
  final String? contentTypeId;
  final double? latitude;
  final double? longitude;
  final List<String> qualityFlags;

  Place withFlag(String flag) => Place(
    id: id,
    title: title,
    category: category,
    address: address,
    imageUrl: imageUrl,
    contentTypeId: contentTypeId,
    latitude: latitude,
    longitude: longitude,
    qualityFlags: [...qualityFlags, flag],
  );

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    address: json['address'] as String?,
    imageUrl: json['image_url'] as String?,
    contentTypeId: json['content_type_id'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    qualityFlags: (json['quality_flags'] as List<dynamic>? ?? const [])
        .cast<String>(),
  );
}

class PlacePage {
  const PlacePage({required this.items, required this.totalCount});

  final List<Place> items;
  final int totalCount;

  factory PlacePage.fromJson(Map<String, dynamic> json) => PlacePage(
    items: (json['items'] as List<dynamic>)
        .map((item) => Place.fromJson(item as Map<String, dynamic>))
        .toList(),
    totalCount: json['total_count'] as int,
  );
}

class PlaceDetail extends Place {
  const PlaceDetail({
    required super.id,
    required super.title,
    required super.category,
    super.address,
    super.imageUrl,
    super.contentTypeId,
    super.latitude,
    super.longitude,
    super.qualityFlags,
    this.overview,
    this.phone,
    this.openingHours,
    this.closedDays,
    this.fee,
    required this.source,
    required this.sourceUrl,
  });

  final String? overview;
  final String? phone;
  final String? openingHours;
  final String? closedDays;
  final String? fee;
  final String source;
  final String sourceUrl;

  factory PlaceDetail.fromJson(Map<String, dynamic> json) => PlaceDetail(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    address: json['address'] as String?,
    imageUrl: json['image_url'] as String?,
    contentTypeId: json['content_type_id'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    qualityFlags: (json['quality_flags'] as List<dynamic>? ?? const [])
        .cast<String>(),
    overview: json['overview'] as String?,
    phone: json['phone'] as String?,
    openingHours: json['opening_hours'] as String?,
    closedDays: json['closed_days'] as String?,
    fee: json['fee'] as String?,
    source: json['source'] as String,
    sourceUrl: json['source_url'] as String,
  );
}
