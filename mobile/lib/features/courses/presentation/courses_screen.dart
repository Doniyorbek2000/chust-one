import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/providers/auth_provider.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  String _selectedCategory = 'Barchasi';
  String _searchQuery = '';

  bool _isLoading = true;
  List<Map<String, dynamic>> _courses = [];
  List<String> _categories = ['Barchasi'];

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/courses');
      final data = (response.data['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      final cats = <String>{'Barchasi'};
      for (final c in data) {
        final catName = (c['category'] as Map<String, dynamic>?)?['nameUz'] as String?;
        if (catName != null) cats.add(catName);
      }
      if (mounted) {
        setState(() {
          _courses = data;
          _categories = cats.toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredCourses = _courses.where((c) {
      final catName = (c['category'] as Map<String, dynamic>?)?['nameUz'] as String?;
      final title = (c['titleUz'] as String? ?? '').toLowerCase();
      final subtitle = (c['subtitleUz'] as String? ?? '').toLowerCase();
      final matchesCategory = _selectedCategory == 'Barchasi' || catName == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          subtitle.contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy900 : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Barcha kurslar'),
        backgroundColor: isDark ? AppColors.navy900 : Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.navy900 : Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Kurslarni qidirish...',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryLime, size: 22),
                    filled: true,
                    fillColor: isDark ? AppColors.navy800 : const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primaryLime, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Category Chips
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat == _selectedCategory;

                      final chipBg = isSelected
                          ? (isDark ? AppColors.primaryLime : const Color(0xFF041426))
                          : (isDark ? AppColors.navy800 : Colors.white);
                      final chipText = isSelected
                          ? (isDark ? AppColors.navy900 : Colors.white)
                          : (isDark ? Colors.white : const Color(0xFF334155));
                      final chipBorder = isSelected
                          ? (isDark ? AppColors.primaryLime : const Color(0xFF041426))
                          : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1));

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedCategory = cat),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: chipBorder),
                            ),
                            child: Row(
                              children: [
                                if (isSelected) ...[
                                  Icon(Icons.check, size: 14, color: chipText),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  cat,
                                  style: TextStyle(
                                    color: chipText,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Course Cards list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLime))
                : filteredCourses.isEmpty
                    ? Center(
                        child: Text(
                          'Kurslar topilmadi',
                          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = filteredCourses[index];
                          final price = course['price'] as num;
                          final discountPrice = course['discountPrice'] as num?;
                          final rating = (course['rating'] as num?)?.toDouble() ?? 5.0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.navy800 : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.08 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () => context.push('/course-detail/${course['id']}'),
                              borderRadius: BorderRadius.circular(20),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                                    child: Image.network(
                                      course['coverImage'] as String? ?? '',
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 120,
                                        height: 120,
                                        color: AppColors.navy700,
                                        child: const Icon(Icons.school, color: AppColors.primaryLime),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  course['titleUz'] as String? ?? '',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    rating.toStringAsFixed(1),
                                                    style: TextStyle(
                                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            course['subtitleUz'] as String? ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          Text(
                                            '${(discountPrice ?? price).toStringAsFixed(0)} so\'m/oy',
                                            style: TextStyle(
                                              color: isDark ? AppColors.primaryLime : const Color(0xFF059669),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
