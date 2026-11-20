import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/catalog_provider.dart';
import '../../services/search_history_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounceTimer;
  List<String> _suggestions = [];
  List<String> _recentSearches = [];
  bool _isLoadingSuggestions = false;

  Position? _currentPosition;
  double _searchRadiusKm = 10.0;
  bool _isGettingLocation = false;

  static const List<String> _popularSearches = [
    'Fresh Watermelon',
    'Hiking Backpack',
    'Headphones',
    'Running Shoes',
    'Smart Watch',
    'Handicrafts',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final history = await SearchHistoryService.getRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearches = history;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() => _isLoadingSuggestions = true);

    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      final service = ref.read(catalogServiceProvider);
      final results = await service.getSuggestions(query.trim());
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  Future<void> _submitSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    await SearchHistoryService.addSearch(trimmed);

    if (mounted) {
      if (_currentPosition != null) {
        context.push(
          '/shop?q=${Uri.encodeComponent(trimmed)}&lat=${_currentPosition!.latitude}&lng=${_currentPosition!.longitude}&radius=$_searchRadiusKm',
        );
      } else {
        context.push('/search?q=${Uri.encodeComponent(trimmed)}');
      }
    }
  }

  Future<void> _showLocationPicker() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: AppColors.primaryOrange),
                      const SizedBox(width: 8),
                      const Text(
                        'Location-Based Product Search',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Search products and sellers near your current GPS position.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  if (_currentPosition != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.paleOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.primaryOrange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Location set: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text('Search Radius:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Slider(
                    value: _searchRadiusKm,
                    min: 1.0,
                    max: 50.0,
                    divisions: 49,
                    activeColor: AppColors.primaryOrange,
                    label: '${_searchRadiusKm.toStringAsFixed(0)} km',
                    onChanged: (val) {
                      setSheetState(() => _searchRadiusKm = val);
                      setState(() => _searchRadiusKm = val);
                    },
                  ),
                  Center(
                    child: Text('${_searchRadiusKm.toStringAsFixed(0)} kilometers radius', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _isGettingLocation
                        ? null
                        : () async {
                            setSheetState(() => _isGettingLocation = true);
                            try {
                              LocationPermission permission = await Geolocator.checkPermission();
                              if (permission == LocationPermission.denied) {
                                permission = await Geolocator.requestPermission();
                              }
                              if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Location permission is required for nearby search.')),
                                  );
                                }
                                return;
                              }

                              final pos = await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                              );

                              setState(() => _currentPosition = pos);
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to get location: $e')),
                                );
                              }
                            } finally {
                              setSheetState(() => _isGettingLocation = false);
                            }
                          },
                    icon: _isGettingLocation
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.gps_fixed),
                    label: Text(_currentPosition != null ? 'Update GPS Location' : 'Use Current GPS Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          onSubmitted: _submitSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search products, brands, categories...',
            hintStyle: const TextStyle(fontSize: 13.5, color: Colors.grey),
            border: InputBorder.none,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
                IconButton(
                  icon: Icon(
                    Icons.location_on,
                    color: _currentPosition != null ? AppColors.primaryOrange : Colors.grey,
                  ),
                  tooltip: 'Nearby Search',
                  onPressed: _showLocationPicker,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Active Location Banner
          if (_currentPosition != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.paleOrange,
              child: Row(
                children: [
                  const Icon(Icons.my_location, size: 16, color: AppColors.primaryOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nearby Search Active (${_searchRadiusKm.toStringAsFixed(0)} km radius)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _currentPosition = null),
                    child: const Icon(Icons.close, size: 16, color: AppColors.primaryOrange),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),

          // Search Suggestions / Fallback View
          Expanded(
            child: _isLoadingSuggestions
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange)))
                : query.isNotEmpty && _suggestions.isNotEmpty
                    ? ListView.builder(
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            leading: const Icon(Icons.search, size: 18, color: Colors.grey),
                            title: Text(suggestion, style: const TextStyle(fontSize: 14)),
                            onTap: () => _submitSearch(suggestion),
                          );
                        },
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Recent Searches Section
                          if (_recentSearches.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Searches',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await SearchHistoryService.clearHistory();
                                    _loadRecentSearches();
                                  },
                                  child: const Text('Clear All', style: TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _recentSearches.map<Widget>((item) {
                                return InputChip(
                                  avatar: const Icon(Icons.history, size: 14, color: Colors.grey),
                                  label: Text(item, style: const TextStyle(fontSize: 12)),
                                  backgroundColor: Colors.grey[100],
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () async {
                                    await SearchHistoryService.removeSearch(item);
                                    _loadRecentSearches();
                                  },
                                  onPressed: () => _submitSearch(item),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Popular Searches Section
                          const Text(
                            'Popular Searches',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _popularSearches.map((item) {
                              return ActionChip(
                                avatar: const Icon(Icons.local_fire_department, size: 14, color: AppColors.primaryOrange),
                                label: Text(item, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                backgroundColor: AppColors.paleOrange,
                                side: BorderSide.none,
                                onPressed: () => _submitSearch(item),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
