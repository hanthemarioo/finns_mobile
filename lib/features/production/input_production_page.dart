import 'package:finns_mobile/features/production/widgets/egg_input_form.dart';
import 'package:finns_mobile/features/production/widgets/meat_input_form.dart';
import 'package:finns_mobile/models/egg_production_model.dart';
import 'package:finns_mobile/models/flock_model.dart';
import 'package:finns_mobile/models/meat_production_model.dart';
import 'package:finns_mobile/providers/auth_provider.dart';
import 'package:finns_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InputProductionPage extends StatefulWidget {
  final EggProduction? eggRecord;
  final MeatProduction? meatRecord;

  const InputProductionPage({super.key, this.eggRecord, this.meatRecord});

  @override
  State<InputProductionPage> createState() => _InputProductionPageState();
}

class _InputProductionPageState extends State<InputProductionPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Future<List<Flock>>? _flocksFuture;

  // --- 2. DECLARE THE MANUAL CONTROLLER ---
  late TabController _tabController;

  bool get _isEditMode => widget.eggRecord != null || widget.meatRecord != null;
  bool get _isEggMode => widget.eggRecord != null;

  @override
  void initState() {
    super.initState();

    // --- 3. INITIALIZE THE CONTROLLER HERE ---
    // Calculate the correct starting index.
    final initialTabIndex = _isEditMode ? (_isEggMode ? 0 : 1) : 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTabIndex,
    );

    if (!_isEditMode) {
      _loadAndFilterFlocks();
    }
  }

  // --- 4. DISPOSE THE CONTROLLER ---
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAndFilterFlocks() {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    // Set the future to trigger the FutureBuilder
    setState(() {
      _flocksFuture = _apiService.getFlock(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Production' : 'Input Production'),
        bottom: TabBar(
          // --- 6. PASS THE MANUAL CONTROLLER ---
          controller: _tabController,
          // The onTap logic remains the same, it's still useful
          onTap: _isEditMode
              ? (index) {
                  if (index != _tabController.index) {
                    _tabController.animateTo(_tabController.index);
                  }
                }
              : null,
          tabs: const [
            Tab(icon: Icon(Icons.egg_alt_outlined), text: 'Egg'),
            Tab(icon: Icon(Icons.set_meal_outlined), text: 'Meat'),
          ],
        ),
      ),
      body: _buildBody(context),
    );
  }

  // A helper method to keep the main build method clean
  Widget _buildBody(BuildContext context) {
    // --- EDIT MODE LOGIC ---
    final bodyContent = _isEditMode
        ? TabBarView(
            controller: _tabController,
            // Prevent swiping between tabs in edit mode
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // ALWAYS build the Egg form. Pass the record if we have it, otherwise pass null.
              EggInputForm(
                recordToEdit: _isEggMode ? widget.eggRecord : null,
                flocks: const [], // Not needed in edit mode
              ),
              // ALWAYS build the Meat form. Pass the record if we have it, otherwise pass null.
              MeatInputForm(
                recordToEdit: !_isEggMode ? widget.meatRecord : null,
                flocks: const [], // Not needed in edit mode
              ),
            ],
          )
        : FutureBuilder<List<Flock>>(
            future: _flocksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Text('Error: ${snapshot.error ?? "No data"}'),
                );
              }
              final layerFlocks = snapshot.data!
                  .where((f) => f.faseType == 'Layer')
                  .toList();
              final growerFlocks = snapshot.data!
                  .where((f) => f.faseType == 'Grower')
                  .toList();

              // Pass the filtered flocks to the forms.
              // In "Add Mode", no records are passed to edit.
              return TabBarView(
                controller: _tabController,
                children: [
                  EggInputForm(flocks: layerFlocks),
                  MeatInputForm(flocks: growerFlocks),
                ],
              );
            },
          );
    return bodyContent;
  }
}
