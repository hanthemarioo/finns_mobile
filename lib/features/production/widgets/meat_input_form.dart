import 'package:finns_mobile/models/flock_model.dart';
import 'package:finns_mobile/models/meat_production_model.dart';
import 'package:finns_mobile/providers/auth_provider.dart';
import 'package:finns_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// The class is now public
class MeatInputForm extends StatefulWidget {
  final List<Flock> flocks;
  final MeatProduction? recordToEdit; // Now accepts a record to edit

  const MeatInputForm({required this.flocks, this.recordToEdit});

  @override
  State<MeatInputForm> createState() => _MeatInputFormState();
}

class _MeatInputFormState extends State<MeatInputForm> {
  // All the code that was previously inside this class remains exactly the same.
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  String? _selectedFlockId;
  late TextEditingController _dateController;
  late TextEditingController _totalMeatCountController;
  late TextEditingController _totalMeatWeightController;
  late TextEditingController _feedAmountController;
  late TextEditingController _waterAmountController;
  late TextEditingController? _deathCountController;

  bool get _isEditMode => widget.recordToEdit != null;

  @override
  void initState() {
    super.initState();
    _selectedFlockId = widget.recordToEdit?.flockId;
    _totalMeatCountController = TextEditingController(
      text: widget.recordToEdit?.totalMeatCount,
    );
    _totalMeatWeightController = TextEditingController(
      text: widget.recordToEdit?.totalMeatWeight,
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

  Future<void> _submitMeatForm() async {
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
        await _apiService.updateMeatProduction(
          token: token,
          meatProductionId: widget.recordToEdit!.id,
          flockId: _selectedFlockId!,
          date: _dateController.text,
          totalMeatCount: int.parse(_totalMeatCountController.text),
          totalMeatWeight: int.parse(_totalMeatWeightController.text),
          feedAmount: int.parse(_feedAmountController.text),
          waterAmount: int.parse(_waterAmountController.text),
          deathCount: deathCount,
        );
      } else {
        await _apiService.createMeatProduction(
          token: token,
          flockId: _selectedFlockId!,
          date: _dateController.text,
          totalMeatCount: int.parse(_totalMeatCountController.text),
          totalMeatWeight: int.parse(_totalMeatWeightController.text),
          feedAmount: int.parse(_feedAmountController.text),
          waterAmount: int.parse(_waterAmountController.text),
          deathCount: deathCount,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meat production saved!'),
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
                labelText: 'Date',
                hintText: _dateController.text.isNotEmpty
                    ? _dateController.text
                    : 'Enter Date',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Date is required';
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
              controller: _totalMeatCountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Ayam Total',
                hintText: 'e.g., 150',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan jumlah ayam total';
                }
                if (int.tryParse(value) == null) {
                  return 'Masukkan angka valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalMeatWeightController,
              decoration: const InputDecoration(
                labelText: 'Berat Ayam Total',
                hintText: 'e.g., 150',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan berat ayam total';
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
                onPressed: _submitMeatForm,
                child: const Text('Save Meat Production'),
              ),
          ],
        ),
      ),
    );
  }
}
