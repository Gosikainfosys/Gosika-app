import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Address Book', style: TextStyle(fontWeight: FontWeight.bold, color: kNavy, fontSize: 18)),
      ),
      body: addressesAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(addressListProvider.notifier).fetchAddresses(),
              child: ListView(
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.location_off_outlined, size: 70, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('No saved addresses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
                        const SizedBox(height: 6),
                        Text('Add a delivery address to complete orders easily.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(addressListProvider.notifier).fetchAddresses(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final addr = list[index];
                return _AddressCard(address: addr);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(addressListProvider.notifier).fetchAddresses(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/checkout/address/new'),
        label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        backgroundColor: AppColors.primaryOrange,
      ),
    );
  }
}

class _AddressCard extends ConsumerWidget {
  final CustomerAddress address;
  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: address.isDefault ? AppColors.primaryOrange : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.paleOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (address.label != null && address.label!.isNotEmpty ? address.label! : address.addressType).toUpperCase(),
                  style: const TextStyle(color: AppColors.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              if (address.isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'DEFAULT',
                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
                onSelected: (val) async {
                  if (val == 'default') {
                    await ref.read(addressListProvider.notifier).setDefaultAddress(address.id);
                  } else if (val == 'delete') {
                    await ref.read(addressListProvider.notifier).deleteAddress(address.id);
                  }
                },
                itemBuilder: (context) => [
                  if (!address.isDefault)
                    const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (address.fullName != null && address.fullName!.isNotEmpty)
            Text(
              address.fullName!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kNavy),
            ),
          const SizedBox(height: 2),
          Text(
            address.phone,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          Text(
            address.fullDisplayAddress,
            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }
}
