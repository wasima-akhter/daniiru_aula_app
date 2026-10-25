class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPage;
  final String? nextPage;
  final String? previousPage;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPage,
    this.nextPage,
    this.previousPage,
  });

  int get totalPages => totalPage;

  bool get hasNextPage {
    if (nextPage != null) {
      return nextPage!.isNotEmpty;
    }
    if (totalPage > 0) {
      return page < totalPage;
    }
    if (total > 0 && limit > 0) {
      return (page * limit) < total;
    }
    return false;
  }

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    final links = json['links'] is Map<String, dynamic>
        ? json['links'] as Map<String, dynamic>
        : null;

    final parsedTotal = json['total'] as int? ?? 0;
    final parsedLimit = json['limit'] as int? ??
        _extractQueryParam(links?['currentPage']?.toString(), 'limit') ??
        10;
    final parsedTotalPage = json['totalPages'] as int? ??
        json['totalPage'] as int? ??
        (parsedLimit > 0 ? (parsedTotal / parsedLimit).ceil() : 0);
    final parsedPage = json['page'] as int? ??
        _extractQueryParam(links?['currentPage']?.toString(), 'page') ??
        1;

    return PaginationMeta(
      page: parsedPage,
      limit: parsedLimit,
      total: parsedTotal,
      totalPage: parsedTotalPage,
      nextPage: links?['nextPage']?.toString(),
      previousPage: links?['previousPage']?.toString(),
    );
  }

  static int? _extractQueryParam(String? url, String param) {
    if (url == null || url.isEmpty) return null;
    try {
      final uri = Uri.parse(url);
      final val = uri.queryParameters[param];
      return val != null ? int.tryParse(val) : null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPage': totalPage,
      'totalPages': totalPage,
      if (nextPage != null) 'nextPage': nextPage,
      if (previousPage != null) 'previousPage': previousPage,
    };
  }
}

