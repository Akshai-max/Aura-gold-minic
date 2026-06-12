class StockMovement {
  final String id;
  final String inventoryItemId;
  final String? itemName;
  final String movementType;
  final int quantityChange;
  final int quantityBefore;
  final int quantityAfter;
  final String? reference;
  final String? notes;
  final String? supplierId;
  final String? performedBy;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.inventoryItemId,
    this.itemName,
    required this.movementType,
    required this.quantityChange,
    required this.quantityBefore,
    required this.quantityAfter,
    this.reference,
    this.notes,
    this.supplierId,
    this.performedBy,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as String,
      inventoryItemId: json['inventory_item_id'] as String,
      itemName: json['item_name'] as String?,
      movementType: json['movement_type'] as String? ?? '',
      quantityChange: json['quantity_change'] as int? ?? 0,
      quantityBefore: json['quantity_before'] as int? ?? 0,
      quantityAfter: json['quantity_after'] as int? ?? 0,
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
      supplierId: json['supplier_id'] as String?,
      performedBy: json['performed_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get displayType {
    switch (movementType) {
      case 'stock_in':
        return 'Stock In';
      case 'stock_out':
        return 'Stock Out';
      case 'adjustment':
        return 'Adjustment';
      default:
        return movementType;
    }
  }
}

class PaginatedStockMovements {
  final List<StockMovement> items;
  final int total;
  final int skip;
  final int limit;

  const PaginatedStockMovements({
    required this.items,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory PaginatedStockMovements.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => StockMovement.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedStockMovements(
      items: items,
      total: json['total'] as int? ?? items.length,
      skip: json['skip'] as int? ?? 0,
      limit: json['limit'] as int? ?? items.length,
    );
  }
}
