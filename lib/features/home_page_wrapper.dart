import 'package:finns_mobile/features/location/location_page.dart';
import 'package:finns_mobile/models/location_model.dart';
import 'package:finns_mobile/services/api_service.dart';
import 'package:finns_mobile/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/production/production_page.dart';

class HomePageWrapper extends StatefulWidget {
  const HomePageWrapper({super.key});

  @override
  State<HomePageWrapper> createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();

  // --- 1. The Futures for our pages will now live here in the parent ---
  late Future<List<Location>>? _locationsFuture;
  // late Future<...> _productionFuture; // etc. for other pages

  // A flag to know if we are currently loading.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the context is ready
    // when we first load the data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    // We can safely use `!` here because this page only builds after a successful login.
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    setState(() {
      _locationsFuture = _apiService.getLocations(token);
      _isLoading =
          false; // We are no longer loading, the FutureBuilder will take over.
    });
  }

  // --- 3. The refresh logic also lives here now ---
  Future<void> _refreshLocations() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    setState(() {
      _locationsFuture = _apiService.getLocations(token);
    });
    // Await the new future to satisfy the RefreshIndicator
    await _locationsFuture;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

  void _handleDeleteLocation(Location location) {
    _showDeleteConfirmationDialog(
      title: 'Delete Location?',
      content:
          'Are you sure you want to delete "${location.name}"? This action cannot be undone and will delete all associated sheds and flocks.',
      onConfirm: () async {
        try {
          final token = Provider.of<AuthProvider>(
            context,
            listen: false,
          ).token!;
          await _apiService.deleteLocation(token, location.id);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
          _refreshLocations(); // Refresh the list
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- 2. THE FIX: Conditionally build the UI ---
    // While the initial data is being fetched, show a loading screen.
    if (_isLoading || _locationsFuture == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // At the top of _HomePageWrapperState
    // --- 4. Pass the future and the refresh function down to the child page ---
    final List<Widget> widgetOptions = <Widget>[
      const HomePage(),
      LocationPage(
        locationsFuture: _locationsFuture!,
        onRefresh: _refreshLocations, // Pass the refresh function
        onDelete: _handleDeleteLocation, // Pass the refresh function
      ),
      const ProductionPage(),
    ];
    // We get the page title from the selected index
    final List<String> pageTitles = ['Home', 'Locations', 'Production'];

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]), // Dynamic title
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              await authService.logout();
              if (mounted) {
                // Update the AuthProvider state
                Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).setAuthToken(null);
                // Manually navigate and clear all previous routes
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Center(child: widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Locations',
          ), // Updated icon and label
          BottomNavigationBarItem(
            icon: Icon(Icons.production_quantity_limits),
            label: 'Production',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
