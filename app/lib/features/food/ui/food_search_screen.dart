import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/food/data/food_repository.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _queryCtrl = TextEditingController();

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryCtrl.text.trim();
    final results = ref.watch(offSearchResultsProvider(query));

    return Scaffold(
      appBar: AppBar(title: const Text('Search Foods')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _queryCtrl,
              decoration: InputDecoration(
                hintText: 'Search e.g. chicken breast',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() {}),
                ),
              ),
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (foods) {
                if (query.isEmpty) return const Center(child: Text('Enter a query to search'));
                if (foods.isEmpty) return const Center(child: Text('No results'));
                return ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (ctx, i) {
                    final f = foods[i];
                    return ListTile(
                      title: Text(f.name),
                      subtitle: Text('${f.brand ?? ''} ${f.servingDesc ?? ''}'.trim()),
                      trailing: Text('${f.calories} kcal'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
