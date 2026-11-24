import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';

class ScrollableFilterTabs extends StatefulWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const ScrollableFilterTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<ScrollableFilterTabs> createState() => _ScrollableFilterTabsState();
}

class _ScrollableFilterTabsState extends State<ScrollableFilterTabs> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollability);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollability());
  }

  @override
  void didUpdateWidget(ScrollableFilterTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollability());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollability);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollability() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final canLeft = currentScroll > 5;
    final canRight = currentScroll < maxScroll - 5;

    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - 160).clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      (_scrollController.offset + 160).clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (_canScrollLeft)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _scrollLeft,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.chevron_left_rounded, size: 18, color: kNavy),
                ),
              ),
            ),
          ),
        Expanded(
          child: RawScrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thumbColor: AppColors.primaryOrange.withValues(alpha: 0.6),
            radius: const Radius.circular(8),
            thickness: 3,
            padding: const EdgeInsets.only(bottom: 1),
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: widget.labels.length,
                itemBuilder: (context, index) {
                  final isSelected = widget.selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        widget.labels[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : kNavy,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) widget.onTabSelected(index);
                      },
                      selectedColor: AppColors.primaryOrange,
                      backgroundColor: Colors.grey[100],
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryOrange : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (_canScrollRight)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _scrollRight,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.chevron_right_rounded, size: 18, color: kNavy),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
