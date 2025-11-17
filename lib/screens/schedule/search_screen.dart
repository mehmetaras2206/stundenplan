import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';
import '../../models/schedule_item.dart';
import '../../widgets/schedule_item_card.dart';
import 'add_edit_schedule_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ScheduleItem> _searchResults = [];
  String? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query, ScheduleProvider provider) {
    if (query.isEmpty && _selectedCategoryId == null) {
      setState(() => _searchResults = []);
      return;
    }

    var items = provider.scheduleItems;

    // Filter by search query
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      items = items.where((item) {
        return item.title.toLowerCase().contains(lowerQuery) ||
            (item.description?.toLowerCase().contains(lowerQuery) ?? false) ||
            (item.location?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }

    // Filter by category
    if (_selectedCategoryId != null) {
      items = items.where((item) => item.categoryId == _selectedCategoryId).toList();
    }

    setState(() => _searchResults = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Termine durchsuchen...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          onChanged: (query) {
            final provider = context.read<ScheduleProvider>();
            _performSearch(query, provider);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty || _selectedCategoryId != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedCategoryId = null;
                  _searchResults = [];
                });
              },
            ),
        ],
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Category filter
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    FilterChip(
                      label: const Text('Alle'),
                      selected: _selectedCategoryId == null,
                      onSelected: (selected) {
                        setState(() => _selectedCategoryId = null);
                        _performSearch(_searchController.text, provider);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...provider.categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: CircleAvatar(
                            backgroundColor: category.color,
                            radius: 12,
                          ),
                          label: Text(category.name),
                          selected: _selectedCategoryId == category.id,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId = selected ? category.id : null;
                            });
                            _performSearch(_searchController.text, provider);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Search results
              Expanded(
                child: _searchController.text.isEmpty && _selectedCategoryId == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Suchen Sie nach Terminen',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Geben Sie einen Suchbegriff ein oder wählen Sie eine Kategorie',
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'Keine Ergebnisse gefunden',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final item = _searchResults[index];
                              return ScheduleItemCard(
                                item: item,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddEditScheduleScreen(item: item),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
