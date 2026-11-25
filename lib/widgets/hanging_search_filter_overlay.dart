import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/product.dart';

class HangingSearchFilterOverlay extends StatefulWidget {
  final bool isFilterTab;
  final String searchQuery;
  final TextEditingController searchController;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final RangeValues priceRangeValues;
  final int? selectedRating;
  final Set<String> selectedBrands;
  final Set<String> selectedCategories;
  final List<Category> categories;
  final List<Map<String, String>> brands;
  final List<Product> products;
  final ValueChanged<bool> onFilterTabChanged;
  final ValueChanged<String> onSearchQueryChanged;
  final ValueChanged<RangeValues> onPriceRangeChanged;
  final ValueChanged<int?> onRatingChanged;
  final VoidCallback onReset;
  final VoidCallback onClose;
  final ValueChanged<Product>? onSelectProduct;
  final ValueChanged<String>? onSelectCategory;
  final ValueChanged<String>? onSelectBrand;

  const HangingSearchFilterOverlay({
    super.key,
    required this.isFilterTab,
    required this.searchQuery,
    required this.searchController,
    required this.minPriceController,
    required this.maxPriceController,
    required this.priceRangeValues,
    required this.selectedRating,
    required this.selectedBrands,
    required this.selectedCategories,
    required this.categories,
    required this.brands,
    required this.products,
    required this.onFilterTabChanged,
    required this.onSearchQueryChanged,
    required this.onPriceRangeChanged,
    required this.onRatingChanged,
    required this.onReset,
    required this.onClose,
    this.onSelectProduct,
    this.onSelectCategory,
    this.onSelectBrand,
  });

  @override
  State<HangingSearchFilterOverlay> createState() => _HangingSearchFilterOverlayState();
}

class _HangingSearchFilterOverlayState extends State<HangingSearchFilterOverlay> {
  bool _showMoreBrands = false;

  @override
  Widget build(BuildContext context) {
    final liveProductSuggestions = widget.searchQuery.isEmpty
        ? widget.products.take(4).toList()
        : widget.products
            .where((p) => p.name.toLowerCase().contains(widget.searchQuery.toLowerCase()))
            .take(5)
            .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar of Hanging Overlay (Expanded title prevents horizontal overflow)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isFilterTab ? Icons.tune_rounded : Icons.search_rounded,
                  color: AppColors.primaryOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isFilterTab ? 'Filters & Sorting' : 'Suggestions & Nearby Search',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.onReset,
                child: const Text(
                  'Reset',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.darkText),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const Divider(height: 16),

          // 1. NEARBY LOCATION (USE GPS BUTTON)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location_rounded, color: AppColors.primaryOrange, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nearby Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.darkText)),
                      Text('Kathmandu Metropolitan City, Nepal', style: TextStyle(fontSize: 10.5, color: AppColors.secondaryText)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Updated delivery location to current GPS location!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Use GPS',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // MODE 1: SEARCH OVERLAY MODE (REAL API PRODUCT & CATEGORY MATCHES)
          if (!widget.isFilterTab) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Suggestions',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.darkText),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: const Row(
                    children: [
                      Text('See all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primaryOrange),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Real API Live Suggestion Items List
            if (liveProductSuggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No matching products found.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              )
            else
              Column(
                children: liveProductSuggestions.map((p) {
                  final imgUrl = ApiClient.apiImage(p.image);
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imgUrl.isNotEmpty
                            ? Image.network(
                                imgUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 40,
                                  height: 40,
                                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                                  child: const Icon(Icons.shopping_bag_outlined, size: 22, color: AppColors.primaryOrange),
                                ),
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                                child: const Icon(Icons.shopping_bag_outlined, size: 22, color: AppColors.primaryOrange),
                              ),
                      ),
                      title: _buildRichSuggestionTitle(p.name, widget.searchQuery),
                      subtitle: Text(formatNPR(p.price), style: const TextStyle(fontSize: 11, color: AppColors.primaryOrange, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                      onTap: () {
                        widget.searchController.text = p.name;
                        widget.onSearchQueryChanged(p.name);
                        widget.onClose();
                        if (widget.onSelectProduct != null) {
                          widget.onSelectProduct!(p);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),

            // Quick Real API Category & Brand Recommendation Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (widget.categories.isNotEmpty)
                    _buildQuickCategoryChip(
                      icon: Icons.grid_view_rounded,
                      iconBgColor: AppColors.primaryOrange,
                      title: widget.categories.first.name,
                      count: 'Categories',
                      onTap: () {
                        widget.searchController.text = widget.categories.first.name;
                        widget.onSearchQueryChanged(widget.categories.first.name);
                        widget.onClose();
                        if (widget.onSelectCategory != null) {
                          widget.onSelectCategory!(widget.categories.first.name);
                        }
                      },
                    ),
                  if (widget.categories.length > 1) ...[
                    const SizedBox(width: 8),
                    _buildQuickCategoryChip(
                      icon: Icons.category_rounded,
                      iconBgColor: const Color(0xFF2196F3),
                      title: widget.categories[1].name,
                      count: 'Explore',
                      onTap: () {
                        widget.searchController.text = widget.categories[1].name;
                        widget.onSearchQueryChanged(widget.categories[1].name);
                        widget.onClose();
                        if (widget.onSelectCategory != null) {
                          widget.onSelectCategory!(widget.categories[1].name);
                        }
                      },
                    ),
                  ],
                  if (widget.brands.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildQuickCategoryChip(
                      icon: Icons.local_offer_rounded,
                      iconBgColor: const Color(0xFF9C27B0),
                      title: widget.brands.first['name'] ?? 'Brands',
                      count: '${widget.brands.length}+ brands',
                      onTap: () {
                        widget.onFilterTabChanged(true);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],

          // MODE 2: FILTER OVERLAY MODE (REAL API CATEGORIES & BRANDS)
          if (widget.isFilterTab) ...[
            // 1. Price Range (NPR)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Price Range (NPR)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkText),
                ),
                Text(
                  'NPR ${(widget.priceRangeValues.start / 1000).round()}k – ${(widget.priceRangeValues.end / 1000).round()}k',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                ),
              ],
            ),
            RangeSlider(
              values: widget.priceRangeValues,
              min: 0,
              max: 150000,
              divisions: 150,
              activeColor: AppColors.primaryOrange,
              inactiveColor: Colors.grey[200],
              onChanged: (values) {
                widget.onPriceRangeChanged(values);
                widget.minPriceController.text = values.start.round().toString();
                widget.maxPriceController.text = values.end.round().toString();
              },
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      controller: widget.minPriceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          widget.onPriceRangeChanged(RangeValues(parsed, widget.priceRangeValues.end));
                        }
                      },
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      controller: widget.maxPriceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: '150,000',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null) {
                          widget.onPriceRangeChanged(RangeValues(widget.priceRangeValues.start, parsed));
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 2. Rating Filter Option List
            const Text(
              'Rating',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            const SizedBox(height: 6),
            Column(
              children: [4, 3, 2, 1].map((stars) {
                final isSelected = widget.selectedRating == stars;
                return InkWell(
                  onTap: () {
                    widget.onRatingChanged(isSelected ? null : stars);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          size: 18,
                          color: isSelected ? AppColors.primaryOrange : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: i < stars ? const Color(0xFFFFB800) : Colors.grey[300],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$stars & above',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // 3. Real API Brands Checkboxes
            if (widget.brands.isNotEmpty) ...[
              const Text(
                'Brand',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkText),
              ),
              const SizedBox(height: 4),
              ...(
                _showMoreBrands ? widget.brands : widget.brands.take(4)
              ).map((b) {
                final brandName = b['name'] ?? '';
                final isChecked = widget.selectedBrands.contains(brandName);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        widget.selectedBrands.remove(brandName);
                      } else {
                        widget.selectedBrands.add(brandName);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: isChecked,
                            activeColor: AppColors.primaryOrange,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  widget.selectedBrands.add(brandName);
                                } else {
                                  widget.selectedBrands.remove(brandName);
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(brandName, style: const TextStyle(fontSize: 12, color: AppColors.darkText)),
                      ],
                    ),
                  ),
                );
              }),
              if (widget.brands.length > 4)
                GestureDetector(
                  onTap: () => setState(() => _showMoreBrands = !_showMoreBrands),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          _showMoreBrands ? 'See Less' : 'See More (${widget.brands.length - 4} more)',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
                        ),
                        Icon(_showMoreBrands ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: AppColors.primaryOrange),
                      ],
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 8),

            // 4. Real API Categories Checkboxes
            if (widget.categories.isNotEmpty) ...[
              const Text(
                'Category',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkText),
              ),
              const SizedBox(height: 4),
              ...widget.categories.map((c) {
                final catName = c.name;
                final isChecked = widget.selectedCategories.contains(catName);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        widget.selectedCategories.remove(catName);
                      } else {
                        widget.selectedCategories.add(catName);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: isChecked,
                            activeColor: AppColors.primaryOrange,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  widget.selectedCategories.add(catName);
                                } else {
                                  widget.selectedCategories.remove(catName);
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(catName, style: const TextStyle(fontSize: 12, color: AppColors.darkText)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],

          const SizedBox(height: 16),

          // Apply & Search Actions Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: widget.onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                elevation: 2,
              ),
              child: Text(
                widget.isFilterTab ? 'Apply Filters & View Results' : 'Search & View Results',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichSuggestionTitle(String title, String query) {
    if (query.isEmpty) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
      );
    }
    final index = title.toLowerCase().indexOf(query.toLowerCase());
    if (index == -1) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
      );
    }
    final before = title.substring(0, index);
    final match = title.substring(index, index + query.length);
    final after = title.substring(index + query.length);

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: AppColors.darkText),
        children: [
          TextSpan(text: before),
          TextSpan(text: match, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText)),
          TextSpan(text: after),
        ],
      ),
    );
  }

  Widget _buildQuickCategoryChip({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBgColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconBgColor),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
