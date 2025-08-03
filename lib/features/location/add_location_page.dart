import 'package:finns_mobile/models/location_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/services/api_service.dart';

class AddLocationPage extends StatefulWidget {
  final Location? location;

  const AddLocationPage({super.key, this.location});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  late TextEditingController _locationName;
  late TextEditingController _locationAddress;
  late TextEditingController _locationDescription;

  // A flag to easily check which mode we are in
  bool get _isEditMode => widget.location != null;

  @override
  void initState() {
    super.initState();

    // Initialize controllers and pre-fill them if in Edit Mode
    _locationName = TextEditingController(text: widget.location?.name);
    _locationAddress = TextEditingController(text: widget.location?.address);
    _locationDescription = TextEditingController(
      text: widget.location?.description,
    );
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _locationName.dispose();
    _locationAddress.dispose();
    _locationDescription.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't submit if form is invalid
    }
    _formKey.currentState!.save(); // Triggers onSaved for all fields
    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      if (_isEditMode) {
        // --- UPDATE LOGIC ---
        await _apiService.updateLocation(
          token: token,
          locationId: widget.location!.id, // Use the existing location's ID
          name: _locationName.text,
          address: _locationAddress.text,
          description: _locationDescription.text,
        );
      } else {
        // --- CREATE LOGIC ---
        await _apiService.createLocation(
          token: token,
          name: _locationName.text,
          address: _locationAddress.text,
          description: _locationDescription.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Also check before popping the navigator
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create location: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Location')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nama Lokasi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Masukkan nama lokasi'
                    : null,
                controller: _locationName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Masukkan alamat' : null,
                controller: _locationAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                controller: _locationDescription,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isEditMode ? 'Update Location' : 'Save Location',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
