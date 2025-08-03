import 'package:finns_mobile/features/location/add_shed_page.dart';
import 'package:finns_mobile/models/flock_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/shed_model.dart';
import '/providers/auth_provider.dart';
import '/services/api_service.dart';

class AddFlockPage extends StatefulWidget {
  final int locationId;
  final Flock? flock;

  const AddFlockPage({super.key, required this.locationId, this.flock});

  @override
  State<AddFlockPage> createState() => _AddFlockPageState();
}

class _AddFlockPageState extends State<AddFlockPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isSubmitting = false;

  // State for the Shed dropdown
  List<Shed> _availableSheds = [];
  bool _isLoadingSheds = true;
  String? _selectedShedId;
  String? _selectedFaseType;

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _initialPopulationController;
  late TextEditingController _breedController;
  late TextEditingController _genderController;
  late TextEditingController _sourceController;
  late TextEditingController? _ageOnArrivalController;
  late TextEditingController _startDateController;

  bool get _isEditMode => widget.flock != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.flock?.name);
    _codeController = TextEditingController(text: widget.flock?.code);
    _selectedFaseType = widget.flock?.faseType;
    _initialPopulationController = TextEditingController(
      text: widget.flock?.initialPopulation.toString(),
    );
    _breedController = TextEditingController(text: widget.flock?.breed);
    _genderController = TextEditingController(text: widget.flock?.gender);
    _sourceController = TextEditingController(text: widget.flock?.source);
    _ageOnArrivalController = TextEditingController(
      text: widget.flock?.ageOnArrival != null
          ? widget.flock!.ageOnArrival.toString()
          : '',
    );
    _selectedShedId = widget.flock?.shedId;

    _startDateController = TextEditingController(
      text:
          widget.flock?.startDate ??
          '', // Jika tidak ada startDate, biarkan kosong
    );

    // Fetch the sheds to populate the dropdown
    _fetchSheds();
  }

  Future<void> _fetchSheds() async {
    setState(() {
      _isLoadingSheds = true;
      _availableSheds = [];
    });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final sheds = await _apiService.getSheds(token, widget.locationId);
      setState(() {
        _availableSheds = sheds;
        _isLoadingSheds = false;
      });
    } catch (e) {
      setState(() => _isLoadingSheds = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sheds: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final quantity = int.parse(_initialPopulationController.text);

      String text = _ageOnArrivalController?.text.trim() ?? '';
      int? ageOnArrival;

      if (text.isNotEmpty) {
        ageOnArrival = int.tryParse(text); // aman karena divalidasi sebelumnya
      }

      if (_isEditMode) {
        await _apiService.updateFlock(
          token: token,
          flockId: widget.flock!.id,
          shedId: _selectedShedId!,
          name: _nameController.text,
          code: _codeController.text,
          startDate: _startDateController.text,
          faseType: _selectedFaseType!,
          initialPopulation: quantity,
          breed: _breedController.text,
          gender: _genderController.text,
          source: _sourceController.text,
          ageOnArrival: ageOnArrival,
        );
      } else {
        await _apiService.createFlock(
          token: token,
          shedId: _selectedShedId!,
          name: _nameController.text,
          code: _codeController.text,
          startDate: _startDateController.text,
          faseType: _selectedFaseType!,
          initialPopulation: quantity,
          breed: _breedController.text,
          gender: _genderController.text,
          source: _sourceController.text,
          ageOnArrival: ageOnArrival,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Flock ${_isEditMode ? 'updated' : 'created'} successfully!',
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
            content: Text('Failed to save flock: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Flock' : 'Add New Flock')),
      body: _buildBody(),
    );
  }

  // A helper method to keep the build method clean
  Widget _buildBody() {
    // State 1: Still loading the initial shed data
    if (_isLoadingSheds) {
      return const Center(child: CircularProgressIndicator());
    }

    // State 2: Loading finished, but no sheds were found
    if (_availableSheds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 60,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Sheds Available',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You must create a shed in this location before you can add a new flock.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create a Shed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // Navigate to the "Add Shed" page
                final result = await Navigator.push<bool?>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddShedPage(locationId: widget.locationId),
                  ),
                );

                // If a shed was successfully created, re-fetch the list
                if (result == true) {
                  _fetchSheds();
                }
              },
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Shed Dropdown ---
            _isLoadingSheds
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedShedId,
                    decoration: const InputDecoration(
                      labelText: 'Shed',
                      border: OutlineInputBorder(),
                    ),
                    items: _availableSheds.map((shed) {
                      return DropdownMenuItem<String>(
                        value: shed.id.toString(),
                        child: Text(shed.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedShedId = value);
                    },
                    validator: (value) =>
                        value == null ? 'Please select a shed' : null,
                  ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Flock Name',
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
                labelText: 'Flock Code',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter a code'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _startDateController,
              decoration: InputDecoration(
                labelText: 'Start Date',
                hintText: _startDateController.text.isNotEmpty
                    ? _startDateController.text
                    : 'Enter Start Date',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Start Date is required';
                }
                return null;
              },
              onTap: () async {
                FocusScope.of(
                  context,
                ).requestFocus(FocusNode()); // Menutup keyboard
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );

                if (pickedDate != null) {
                  // Set the picked date to the controller
                  setState(() {
                    _startDateController.text = pickedDate
                        .toLocal()
                        .toString()
                        .split(' ')[0]; // Format: yyyy-MM-dd
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedFaseType,
              decoration: const InputDecoration(
                labelText: 'Fase Type',
                border: OutlineInputBorder(),
              ),
              items: ['Layer', 'Grower']
                  .map(
                    (label) => DropdownMenuItem(
                      value: label,
                      child: Text('Fase $label'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedFaseType = value);
              },
              validator: (value) =>
                  value == null ? 'Please select a fase type' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _initialPopulationController,
              decoration: const InputDecoration(
                labelText: 'Initial Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _breedController,
              decoration: const InputDecoration(
                labelText: 'Breed',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter a breed'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _genderController,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter a gender'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Source',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageOnArrivalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age On Arrival',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return null; // Boleh kosong
                }
                if (int.tryParse(trimmed) == null) {
                  return 'Masukkan angka yang valid';
                }
                return null; // valid
              },
            ),
            const SizedBox(height: 24),
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isEditMode ? 'Update Flock' : 'Save Flock'),
              ),
          ],
        ),
      ),
    );
  }
}
