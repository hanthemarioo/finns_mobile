import 'package:flutter/material.dart';
import '/models/location_model.dart';
import 'add_location_page.dart';
import 'location_detail_page.dart'; // <-- FIX: Make sure this import is here and correct

class LocationPage extends StatelessWidget {
  /// --- 1. It receives the future and the refresh function as parameters ---
  final Future<List<Location>> locationsFuture;
  final Future<void> Function() onRefresh;
  final void Function(Location) onDelete;

  const LocationPage({
    super.key,
    required this.locationsFuture,
    required this.onRefresh,
    required this.onDelete,
  });

  // The refresh logic needs to be passed down for the Add/Edit buttons
  Future<void> _handleNavigationResult(
    BuildContext context,
    bool? result,
  ) async {
    if (result == true) {
      await onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The Scaffold provides the canvas for the FloatingActionButton
      body: FutureBuilder<List<Location>>(
        future: locationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No locations found. Add one!'));
          } else {
            final locations = snapshot.data!;
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final location = locations[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 8.0,
                    ),
                    // Use InkWell for the tap effect on the entire card
                    child: InkWell(
                      onTap: () {
                        // PRIMARY ACTION: Navigate to details
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LocationDetailPage(location: location),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_city,
                              color: Colors.green,
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            // Use Expanded to make the text part fill the available space
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    location.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(location.address),
                                ],
                              ),
                            ),
                            // SECONDARY ACTION: Edit Button
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              tooltip: 'Edit Location',
                              onPressed: () async {
                                final result = await Navigator.push<bool?>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddLocationPage(
                                      location: location,
                                    ), // Pass the data
                                  ),
                                );
                                await _handleNavigationResult(context, result);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Delete Location',
                              onPressed: () {
                                // --- 3. SIMPLY CALL THE PASSED-IN FUNCTION ---
                                // It has no logic of its own.
                                onDelete(location);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
      // The FloatingActionButton is a property of the Scaffold
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // We now expect the result can be a 'bool' or 'null'.
          // So we type it as 'bool?'. This is the key fix.
          final result = await Navigator.push<bool?>(
            context,
            MaterialPageRoute(builder: (_) => const AddLocationPage()),
          );
          await _handleNavigationResult(context, result);
        },
        backgroundColor: Colors.amber[800],
        child: const Icon(Icons.add),
      ),
    );
  }
}
