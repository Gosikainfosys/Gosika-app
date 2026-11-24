import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants.dart';
import '../core/theme/app_colors.dart';
import '../core/api_client.dart';
import '../models/product.dart';

class VariantSelectorSheet extends StatefulWidget {
  final Product product;
  final ProductVariant? initialVariant;
  final Function(ProductVariant variant, int quantity) onConfirm;

  const VariantSelectorSheet({
    super.key,
    required this.product,
    this.initialVariant,
    required this.onConfirm,
  });

  @override
  State<VariantSelectorSheet> createState() => _VariantSelectorSheetState();
}

class _VariantSelectorSheetState extends State<VariantSelectorSheet> {
  late ProductVariant? _selectedVariant;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.initialVariant ??
        (widget.product.variants.isNotEmpty ? widget.product.variants.first : null);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final currentPrice = _selectedVariant?.price ?? p.price;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Product Header Row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: CachedNetworkImage(
                      imageUrl: ApiClient.apiImage(p.image),
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(color: Colors.grey[100]),
                      errorWidget: (ctx, url, err) => Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.image_outlined, color: kMuted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: kNavy,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatNPR(currentPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),

            // Variant Options
            const Text(
              'Select Option',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kNavy),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.variants.map((v) {
                final isSelected = _selectedVariant?.id == v.id;
                return ChoiceChip(
                  label: Text(v.name ?? 'Variant ${v.id.substring(0, 4)}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedVariant = v);
                    }
                  },
                  selectedColor: AppColors.primaryOrange,
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : kNavy,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryOrange : Colors.grey.shade300,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Quantity Selector Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quantity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kNavy),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_quantity > 1) setState(() => _quantity--);
                        },
                        icon: const Icon(Icons.remove, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedVariant == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        widget.onConfirm(_selectedVariant!, _quantity);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Confirm & Add to Cart',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
