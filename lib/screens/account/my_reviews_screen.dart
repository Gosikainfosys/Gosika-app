import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/review.dart';
import '../../providers/review_provider.dart';

class MyReviewsScreen extends ConsumerStatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  ConsumerState<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends ConsumerState<MyReviewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Reviews', style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryOrange,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.primaryOrange,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'To Review'),
            Tab(text: 'My Reviews'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PendingReviewsTab(),
          _SubmittedReviewsTab(),
        ],
      ),
    );
  }
}

class _PendingReviewsTab extends ConsumerWidget {
  const _PendingReviewsTab();

  void _openReviewModal(BuildContext context, WidgetRef ref, PendingReviewItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WriteReviewSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingReviewsProvider);

    return pendingAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(pendingReviewsProvider.notifier).fetchPendingReviews(),
            child: ListView(
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.rate_review_outlined, size: 70, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No pending reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
                      const SizedBox(height: 4),
                      Text('Delivered items eligible for review will show up here.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(pendingReviewsProvider.notifier).fetchPendingReviews(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    if (item.image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: item.image!,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kNavy), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('Order #${item.orderNumber} • ${formatNPR(item.unitPrice)}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => _openReviewModal(context, ref, item),
                      child: const Text('Review', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _SubmittedReviewsTab extends ConsumerWidget {
  const _SubmittedReviewsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(customerReviewsProvider);

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(customerReviewsProvider.notifier).fetchReviews(),
            child: ListView(
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.star_outline_rounded, size: 70, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No reviews submitted yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(customerReviewsProvider.notifier).fetchReviews(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(review.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kNavy)),
                        const Spacer(),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (review.title != null && review.title!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(review.title!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kNavy)),
                    ],
                    if (review.body != null && review.body!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(review.body!, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                    ],
                    if (review.photos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: review.photos.map((p) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(imageUrl: p, width: 60, height: 60, fit: BoxFit.cover),
                        )).toList(),
                      ),
                    ],
                    if (review.reply != null && review.reply!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Vendor Reply:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kNavy)),
                            const SizedBox(height: 2),
                            Text(review.reply!, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _WriteReviewSheet extends ConsumerStatefulWidget {
  final PendingReviewItem item;
  const _WriteReviewSheet({required this.item});

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  int _rating = 5;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final List<File> _selectedPhotos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedPhotos.addAll(pickedFiles.map((f) => File(f.path)));
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(reviewServiceProvider);
      await service.submitReview(
        productUuid: widget.item.productId,
        rating: _rating,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        orderItemId: widget.item.id,
        photoFiles: _selectedPhotos,
      );

      await ref.read(pendingReviewsProvider.notifier).fetchPendingReviews();
      await ref.read(customerReviewsProvider.notifier).fetchReviews();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!'), backgroundColor: kSuccess),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e'), backgroundColor: kDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Write a Review for ${widget.item.productName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kNavy)),
              const SizedBox(height: 16),

              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setState(() => _rating = index + 1),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _bodyController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Review body (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Photos row
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickPhotos,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: const Text('Add Photos'),
                  ),
                  const SizedBox(width: 12),
                  Text('${_selectedPhotos.length} photo(s) selected', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              if (_selectedPhotos.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedPhotos.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_selectedPhotos[index], width: 60, height: 60, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
