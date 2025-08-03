import 'package:finns_mobile/models/egg_production_model.dart';
import 'package:finns_mobile/models/meat_production_model.dart';
import 'package:finns_mobile/providers/auth_provider.dart';
import 'package:finns_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'input_production_page.dart';

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

// Add SingleTickerProviderStateMixin to handle the TabController animation
class _ProductionPageState extends State<ProductionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  Future<List<dynamic>>? _productionDataFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProductionData();
  }

  Future<void> _loadProductionData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return; // Guard clause

    // 2. Create the future that we will both await and assign to state.
    final future = Future.wait([
      _apiService.getEggProductions(token),
      _apiService.getMeatProductions(token),
    ]);

    // 3. Set the state immediately so the FutureBuilder starts listening.
    // This is what shows the loading spinner in the body.
    setState(() {
      _productionDataFuture = future;
    });

    // 4. Await the future. This is what satisfies the RefreshIndicator.
    // It tells the pull-to-refresh spinner when to disappear.
    await future;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm, // The function to run if the user confirms
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(children: <Widget>[Text(content)]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                onConfirm(); // Execute the delete action
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(icon: Icon(Icons.egg_alt_outlined), text: 'Eggs'),
          Tab(icon: Icon(Icons.set_meal_outlined), text: 'Meat'),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _productionDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No production data found.'));
          }

          // Safely extract the data from the snapshot list
          final eggProductions = snapshot.data![0] as List<EggProduction>;
          final meatProductions = snapshot.data![1] as List<MeatProduction>;

          return TabBarView(
            controller: _tabController,
            children: [
              // Pass the egg data to the first tab
              _buildProductionList(
                items: eggProductions,
                itemBuilder: (context, item) =>
                    _buildEggCard(item as EggProduction),
                onRefresh: _loadProductionData,
              ),
              // Pass the meat data to the second tab
              _buildProductionList(
                items: meatProductions,
                itemBuilder: (context, item) =>
                    _buildMeatCard(item as MeatProduction),
                onRefresh: _loadProductionData,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final int currentIndex = _tabController.index;

          final result = await Navigator.push<bool?>(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  InputProductionPage(initialTabIndex: currentIndex),
            ),
          );
          if (result == true) {
            _loadProductionData(); // Refresh on successful input
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductionList({
    required List<dynamic> items,
    required Widget Function(BuildContext, dynamic) itemBuilder,
    required Future<void> Function() onRefresh,
  }) {
    if (items.isEmpty) {
      return const Center(child: Text('No records for this category.'));
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: items.length,
        itemBuilder: (context, index) => itemBuilder(context, items[index]),
      ),
    );
  }

  // Card UI for a single Egg Production record
  Widget _buildEggCard(EggProduction eggRecord) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.egg, color: Colors.orangeAccent, size: 40),
        title: Text(
          '${eggRecord.totalEggCount} Eggs - Grade ${eggRecord.totalEggWeight}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Flock: ${eggRecord.flockName}\nDate: ${eggRecord.date}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              onPressed: () async {
                final result = await Navigator.push<bool?>(
                  context,
                  MaterialPageRoute(
                    // --- NAVIGATE TO THE SAME INPUT PAGE ---
                    builder: (context) =>
                        InputProductionPage(eggRecord: eggRecord),
                  ),
                );
                if (result == true) _loadProductionData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Delete EggProduction',
              onPressed: () {
                // --- 3. CALL THE CONFIRMATION DIALOG ---
                _showDeleteConfirmationDialog(
                  title: 'Delete EggProduction?',
                  content:
                      'Are you sure you want to delete This Data? This action cannot be undone and will delete pemanently.',
                  onConfirm: () async {
                    try {
                      final token = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).token!;
                      await _apiService.deleteEggProduction(
                        token,
                        eggRecord.id,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('EggProduction deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadProductionData(); // Refresh the list
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Card UI for a single Meat Production record
  Widget _buildMeatCard(MeatProduction meatRecord) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.scale, color: Colors.brown, size: 40),
        title: Text(
          '${meatRecord.totalMeatWeight} kg',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Flock: ${meatRecord.flockName}\nDate: ${meatRecord.date}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              onPressed: () async {
                final result = await Navigator.push<bool?>(
                  context,
                  MaterialPageRoute(
                    // --- NAVIGATE TO THE SAME INPUT PAGE ---
                    builder: (context) =>
                        InputProductionPage(meatRecord: meatRecord),
                  ),
                );
                if (result == true) _loadProductionData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Delete MeatProduction',
              onPressed: () {
                // --- 3. CALL THE CONFIRMATION DIALOG ---
                _showDeleteConfirmationDialog(
                  title: 'Delete MeatProduction?',
                  content:
                      'Are you sure you want to delete This Data? This action cannot be undone and will delete permanently.',
                  onConfirm: () async {
                    try {
                      final token = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).token!;
                      await _apiService.deleteMeatProduction(
                        token,
                        meatRecord.id,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('MeatProduction deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadProductionData(); // Refresh the list
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
