import 'package:finns_mobile/models/egg_production_model.dart';
import 'package:finns_mobile/models/flock_model.dart';
import 'package:finns_mobile/providers/auth_provider.dart';
import 'package:finns_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EggInputForm extends StatefulWidget {
  final List<Flock> flocks;
  final EggProduction? recordToEdit; // Now accepts a record to edit

  const EggInputForm({required this.flocks, this.recordToEdit});

  @override
  State<EggInputForm> createState() => _EggInputFormState();
}

class _EggInputFormState extends State<EggInputForm> {
  // All the code that was previously inside this class remains exactly the same.
  // No changes are needed here.
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  String? _selectedFlockId;
  late TextEditingController _dateController;
  late TextEditingController _totalEggCountController;
  late TextEditingController _totalEggWeightController;
  late TextEditingController _feedAmountController;
  late TextEditingController _waterAmountController;
  late TextEditingController? _deathCountController;

  bool get _isEditMode => widget.recordToEdit != null;

  @override
  void initState() {
    super.initState();
    _selectedFlockId = widget.recordToEdit?.flockId;
    _totalEggCountController = TextEditingController(
      text: widget.recordToEdit?.totalEggCount,
    );
    _totalEggWeightController = TextEditingController(
      text: widget.recordToEdit?.totalEggWeight,
    );
    _feedAmountController = TextEditingController(
      text: widget.recordToEdit?.feedAmount,
    );
    _waterAmountController = TextEditingController(
      text: widget.recordToEdit?.waterAmount,
    );
    _deathCountController = TextEditingController(
      text: widget.recordToEdit?.deathCount,
    );
    _dateController = TextEditingController(
      text:
          widget.recordToEdit?.date ??
          '', // Jika tidak ada startDate, biarkan kosong
    );
  }

  Future<void> _submitEggForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      String text = _deathCountController?.text.trim() ?? '';
      int? deathCount;

      if (text.isNotEmpty) {
        deathCount = int.tryParse(text); // aman karena divalidasi sebelumnya
      }

      if (_isEditMode) {
        await _apiService.updateEggProduction(
          token: token,
          eggProductionId: widget.recordToEdit!.id,
          flockId: _selectedFlockId!,
          date: _dateController.text,
          totalEggCount: int.parse(_totalEggCountController.text),
          totalEggWeight: int.parse(_totalEggWeightController.text),
          feedAmount: int.parse(_feedAmountController.text),
          waterAmount: int.parse(_waterAmountController.text),
          deathCount: deathCount,
        );
      } else {
        await _apiService.createEggProduction(
          token: token,
          flockId: _selectedFlockId!,
          date: _dateController.text,
          totalEggCount: int.parse(_totalEggCountController.text),
          totalEggWeight: int.parse(_totalEggWeightController.text),
          feedAmount: int.parse(_feedAmountController.text),
          waterAmount: int.parse(_waterAmountController.text),
          deathCount: deathCount,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Egg production saved!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditMode && widget.flocks.isEmpty) {
      return const Center(child: Text('No "Layer" type flocks available.'));
    }
    
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedFlockId,
              decoration: InputDecoration(
                labelText: 'Select Flock',
                border: OutlineInputBorder(),
                filled: _isEditMode, // Visually indicate it's disabled
                fillColor: _isEditMode ? Colors.grey[200] : null,
              ),
              items: _isEditMode
                  ? [
                      DropdownMenuItem(
                        value: _selectedFlockId,
                        child: Text(widget.recordToEdit!.flockName),
                      ),
                    ]
                  : widget.flocks
                        .map(
                          (f) => DropdownMenuItem(
                            value: f.id.toString(),
                            child: Text(f.name),
                          ),
                        )
                        .toList(),
              onChanged: _isEditMode
                  ? null
                  : (v) => setState(() => _selectedFlockId = v),
              validator: (v) => v == null ? 'Please select a flock' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Start Date',
                hintText: _dateController.text.isNotEmpty
                    ? _dateController.text
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
                    _dateController.text = pickedDate
                        .toLocal()
                        .toString()
                        .split(' ')[0]; // Format: yyyy-MM-dd
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalEggCountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Telur',
                hintText: 'e.g., 150',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan jumlah telur';
                }
                if (int.tryParse(value) == null) {
                  return 'Masukkan angka valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalEggWeightController,
              decoration: const InputDecoration(
                labelText: 'Berat Telur',
                hintText: 'e.g., 150',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan berat telur';
                }
                if (int.tryParse(value) == null) {
                  return 'Masukkan angka valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deathCountController,
              decoration: const InputDecoration(
                labelText: 'Kematian (Ekor)',
                hintText: 'e.g., 1',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _feedAmountController,
              decoration: const InputDecoration(
                labelText: 'Pakan (Kg)',
                hintText: 'e.g., 100',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan jumlah pakan ayam';
                }
                if (int.tryParse(value) == null) {
                  return 'Masukkan angka valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _waterAmountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Minum (Liter)',
                hintText: 'e.g., 10',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan jumlah minum ayam';
                }
                if (int.tryParse(value) == null) {
                  return 'Masukkan angka valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _submitEggForm,
                child: const Text('Save Egg Production'),
              ),
          ],
        ),
      ),
    );
  }
}
