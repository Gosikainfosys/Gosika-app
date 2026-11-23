import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/product.dart';
import '../models/product_filters.dart';

class FilterSheet extends StatefulWidget {
  final List<Category> categories;
  final List<Map<String, String>> brands;
  final ProductFilters initialFilters;
  final ValueChanged<ProductFilters> onApply;

  const FilterSheet({
    super.key,
    required this.categories,
    required this.brands,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late ProductFilters _filters;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  static const List<Map<String, String>> _priceRangeOptions = [
    {'key': 'under_1000', 'label': 'Under Rs. 1,000'},
    {'key': '1000_5000', 'label': 'Rs. 1,000 – Rs. 5,000'},
    {'key': '5000_15000', 'label': 'Rs. 5,000 – Rs. 15,000'},
    {'key': '15000_50000', 'label': 'Rs. 15,000 – Rs. 50,000'},
    {'key': 'above_50000', 'label': 'Above Rs. 50,000'},
  ];

  static const List<Map<String, String>> _availabilityOptions = [
    {'key': 'in_stock', 'label': 'In Stock'},
    {'key': 'low_stock', 'label': 'Low Stock'},
    {'key': 'out_of_stock', 'label': 'Out of Stock'},
  ];

  static const List<Map<String, String>> _sortOptions = [
    {'key': 'newest', 'label': 'Newest Arrival'},
    {'key': 'price_asc', 'label': 'Price: Low to High'},
    {'key': 'price_desc', 'label': 'Price: High to Low'},
    {'key': 'rating', 'label': 'Top Rated'},
    {'key': 'discount', 'label': 'Biggest Discount'},
    {'key': 'top', 'label': 'Best Selling'},
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters.copyWith();
    if (_filters.minPrice != null) {
      _minPriceController.text = _filters.minPrice!.toStringAsFixed(0);
    }
    if (_filters.maxPrice != null) {
      _maxPriceController.text = _filters.maxPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle and Header
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters & Sorting',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters.reset();
                      _minPriceController.clear();
                      _maxPriceController.clear();
                    });
                  },
                  child: const Text(
                    'Reset All',
                    style: TextStyle(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Filter Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Sorting
                _buildSectionHeader('Sort By'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sortOptions.map((opt) {
                    final isSelected = _filters.sortBy == opt['key'];
                    return ChoiceChip(
                      label: Text(opt['label']!),
                      selected: isSelected,
                      selectedColor: AppColors.primaryOrange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.darkText,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _filters.sortBy = opt['key']!);
                        }
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 2. Category Filter
                _buildSectionHeader('Category'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.categories.map((cat) {
                    final isSelected = _filters.category == cat.slug || _filters.category == cat.id;
                    return FilterChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      selectedColor: AppColors.primaryOrange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.darkText,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _filters.category = selected ? cat.slug : null;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 3. Price Ranges
                _buildSectionHeader('Price Ranges'),
                Column(
                  children: _priceRangeOptions.map((opt) {
                    final isChecked = _filters.priceRanges.contains(opt['key']);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(opt['label']!, style: const TextStyle(fontSize: 13)),
                      value: isChecked,
                      activeColor: AppColors.primaryOrange,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _filters.priceRanges.add(opt['key']!);
                          } else {
                            _filters.priceRanges.remove(opt['key']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 8),

                // Custom Price Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Min (Rs.)',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          _filters.minPrice = double.tryParse(val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('–'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Max (Rs.)',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          _filters.maxPrice = double.tryParse(val);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 4. Rating Filter
                _buildSectionHeader('Minimum Rating'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [4, 3, 2, 1].map((stars) {
                    final isSelected = _filters.minRating == stars;
                    return ChoiceChip(
                      label: Text('$stars★ & above'),
                      selected: isSelected,
                      selectedColor: AppColors.primaryOrange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.darkText,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _filters.minRating = selected ? stars : null;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 5. Availability
                _buildSectionHeader('Availability'),
                Column(
                  children: _availabilityOptions.map((opt) {
                    final isChecked = _filters.availability.contains(opt['key']);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(opt['label']!, style: const TextStyle(fontSize: 13)),
                      value: isChecked,
                      activeColor: AppColors.primaryOrange,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _filters.availability.add(opt['key']!);
                          } else {
                            _filters.availability.remove(opt['key']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 6. Brands
                if (widget.brands.isNotEmpty) ...[
                  _buildSectionHeader('Brands'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.brands.map((b) {
                      final isSelected = _filters.brand == b['slug'];
                      return FilterChip(
                        label: Text(b['name']!),
                        selected: isSelected,
                        selectedColor: AppColors.primaryOrange,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.darkText,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _filters.brand = selected ? b['slug'] : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_filters);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _filters.activeFilterCount > 0
                      ? 'Apply Filters (${_filters.activeFilterCount})'
                      : 'Apply Filters',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
        ),
      ),
    );
  }
}
