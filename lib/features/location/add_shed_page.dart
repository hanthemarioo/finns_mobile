import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/shed_model.dart';
import '/providers/auth_provider.dart';
import '/services/api_service.dart';

class AddShedPage extends StatefulWidget {
  final int locationId; // Required to associate the shed
  final Shed? shed; // Optional: if not null, we are in "Edit Mode"

  const AddShedPage({super.key, required this.locationId, this.shed});

  @override
  State<AddShedPage> createState() => _AddShedPageState();
}

class _AddShedPageState extends State<AddShedPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _codeController;

  bool get _isEditMode => widget.shed != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shed?.name);
    _descriptionController = TextEditingController(
      text: widget.shed?.description,
    );
    _codeController = TextEditingController(text: widget.shed?.code);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;

      if (_isEditMode) {
        // UPDATE Shed
        await _apiService.updateShed(
          token: token,
          shedId: widget.shed!.id,
          locationId: widget.locationId, // Use the passed locationId
          name: _nameController.text,
          description: _descriptionController.text,
          code: _codeController.text,
        );
      } else {
        // CREATE Shed
        await _apiService.createShed(
          token: token,
          locationId: widget.locationId, // Use the passed locationId
          name: _nameController.text,
          description: _descriptionController.text,
          code: _codeController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Shed ${_isEditMode ? 'updated' : 'created'} successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save shed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Shed' : 'Add New Shed')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Shed Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Shed Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
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
                  child: Text(_isEditMode ? 'Update Shed' : 'Save Shed'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
