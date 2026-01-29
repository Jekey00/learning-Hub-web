import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryFilter extends StatefulWidget {
  final String? selectedCategory;
  final Function(String?) onCategoryChanged;

  const CategoryFilter({
    super.key,
    this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  State<CategoryFilter> createState() => _CategoryFilterState();
}

class _CategoryFilterState extends State<CategoryFilter> {
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final supabase = Supabase.instance.client;
    final categories = await supabase
        .from('categories')
        .select()
        .order('name');

    setState(() => _categories = List<Map<String, dynamic>>.from(categories));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          FilterChip(
            label: const Text('Alle'),
            selected: widget.selectedCategory == null,
            onSelected: (_) => widget.onCategoryChanged(null),
          ),
          const SizedBox(width: 8),
          ..._categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('${cat['icon'] ?? ''} ${cat['name']}'),
                selected: widget.selectedCategory == cat['id'],
                onSelected: (_) => widget.onCategoryChanged(cat['id']),
              ),
            );
          }),
        ],
      ),
    );
  }
}
