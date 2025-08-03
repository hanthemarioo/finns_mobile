import 'package:finns_mobile/features/location/add_flock_page.dart';
import 'package:finns_mobile/models/flock_model.dart';
import 'package:finns_mobile/models/shed_model.dart';
import 'package:finns_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/location_model.dart';
import '../../providers/auth_provider.dart';
import 'add_shed_page.dart';

class LocationDetailPage extends StatelessWidget {
  final Location location;

  const LocationDetailPage({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(location.name),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home_work_outlined), text: 'Sheds'),
              Tab(icon: Icon(Icons.groups_2_outlined), text: 'Flocks'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ShedsManagementTab(locationId: location.id),

            FlocksManagementTab(locationId: location.id),
          ],
        ),
      ),
    );
  }
}

class ShedsManagementTab extends StatefulWidget {
  final int locationId;
  const ShedsManagementTab({super.key, required this.locationId});

  @override
  State<ShedsManagementTab> createState() => _ShedsManagementTabState();
}

class _ShedsManagementTabState extends State<ShedsManagementTab> {
  final ApiService _apiService = ApiService();
  late Future<List<Shed>> _shedsFuture;

  @override
  void initState() {
    super.initState();
    _loadSheds();
  }

  void _loadSheds() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      setState(() {
        _shedsFuture = _apiService.getSheds(token, widget.locationId);
      });
    }
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
      body: FutureBuilder<List<Shed>>(
        future: _shedsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No sheds found. Add one!'));
          } else {
            final sheds = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => _loadSheds(),
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: sheds.length,
                itemBuilder: (context, index) {
                  final shed = sheds[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.home_work,
                        color: Colors.blueGrey,
                        size: 40,
                      ),
                      title: Text(
                        shed.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Capacity: ${shed.code}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () async {
                              final result = await Navigator.push<bool?>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddShedPage(
                                    locationId: widget.locationId,
                                    shed: shed, // Pass the existing shed data
                                  ),
                                ),
                              );
                              if (result == true) {
                                _loadSheds(); // Refresh the list on success
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Delete Shed',
                            onPressed: () {
                              // --- 3. CALL THE CONFIRMATION DIALOG ---
                              _showDeleteConfirmationDialog(
                                title: 'Delete Shed?',
                                content:
                                    'Are you sure you want to delete "${shed.name}"? This action cannot be undone and will delete all associated flocks.',
                                onConfirm: () async {
                                  try {
                                    final token = Provider.of<AuthProvider>(
                                      context,
                                      listen: false,
                                    ).token!;
                                    await _apiService.deleteShed(
                                      token,
                                      shed.id,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Shed deleted successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _loadSheds(); // Refresh the list
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to delete: ${e.toString()}',
                                        ),
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
                },
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool?>(
            context,
            MaterialPageRoute(
              builder: (context) => AddShedPage(
                locationId: widget.locationId, // Pass the parent locationId
              ),
            ),
          );
          if (result == true) {
            _loadSheds(); // Refresh the list on success
          }
        },
        tooltip: 'Add Shed',
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FlocksManagementTab extends StatefulWidget {
  final int locationId;
  const FlocksManagementTab({super.key, required this.locationId});

  @override
  State<FlocksManagementTab> createState() => _FlocksManagementTabState();
}

class _FlocksManagementTabState extends State<FlocksManagementTab> {
  final ApiService _apiService = ApiService();
  late Future<List<Flock>> _flocksFuture;

  @override
  void initState() {
    super.initState();
    _loadFlocks();
  }

  void _loadFlocks() {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    setState(() {
      _flocksFuture = _apiService.getFlocksForLocation(
        token,
        widget.locationId,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Flock>>(
        future: _flocksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No flocks found. Add one!'));
          } else {
            final flocks = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => _loadFlocks(),
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: flocks.length,
                itemBuilder: (context, index) {
                  final flock = flocks[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.groups,
                        color: Colors.orange,
                        size: 40,
                      ),
                      title: Text(
                        flock.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${flock.breed} - Quantity: ${flock.initialPopulation}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () async {
                              final result = await Navigator.push<bool?>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddFlockPage(
                                    locationId: widget.locationId,
                                    flock: flock,
                                  ),
                                ),
                              );
                              if (result == true) _loadFlocks();
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Delete Flock',
                            onPressed: () {
                              // --- 3. CALL THE CONFIRMATION DIALOG ---
                              _showDeleteConfirmationDialog(
                                title: 'Delete Flock?',
                                content:
                                    'Are you sure you want to delete "${flock.name}"? This action cannot be undone and will delete all associated flocks.',
                                onConfirm: () async {
                                  try {
                                    final token = Provider.of<AuthProvider>(
                                      context,
                                      listen: false,
                                    ).token!;
                                    await _apiService.deleteFlock(
                                      token,
                                      flock.id,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Flock deleted successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _loadFlocks(); // Refresh the list
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to delete: ${e.toString()}',
                                        ),
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
                },
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool?>(
            context,
            MaterialPageRoute(
              builder: (context) => AddFlockPage(locationId: widget.locationId),
            ),
          );
          if (result == true) _loadFlocks();
        },
        tooltip: 'Add Flock',
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
