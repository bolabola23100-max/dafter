import 'package:flutter/material.dart';

import 'package:dafter/core/utils/id_generator.dart';
import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/model/account.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _accountRepository = AccountRepository();

  String _type = 'صندوق';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  AccountType _mapAccountType(String type) {
    switch (type) {
      case 'بنك':
        return AccountType.bank;
      case 'مصروف':
        return AccountType.expense;
      case 'إيراد':
        return AccountType.income;
      case 'أخرى':
        return AccountType.other;
      case 'صندوق':
      default:
        return AccountType.cash;
    }
  }

  Future<void> _saveAccount() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final balance = double.tryParse(_openingBalanceController.text.trim()) ?? 0;

    if (balance < 0) {
      _message('الرصيد الافتتاحي غير صحيح');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final account = Account(
        id: IdGenerator.generate(),
        name: name,
        type: _mapAccountType(_type),
        openingBalance: balance,
        balance: balance,
      );

      await _accountRepository.addAccount(account);

      if (!mounted) return;
      _message('تم إضافة الحساب بنجاح');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _message('تعذر حفظ الحساب: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة حساب'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CustomTextFormField(
                openingBalanceController: _nameController,
                hintText: 'اسم الحساب',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'أدخل اسم الحساب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'نوع الحساب',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'صندوق', child: Text('صندوق')),
                  DropdownMenuItem(value: 'بنك', child: Text('بنك')),
                  DropdownMenuItem(value: 'مصروف', child: Text('مصروف')),
                  DropdownMenuItem(value: 'إيراد', child: Text('إيراد')),
                  DropdownMenuItem(value: 'أخرى', child: Text('أخرى')),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                openingBalanceController: _openingBalanceController,
                hintText: 'الرصيد الافتتاحي',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final balance = double.tryParse(value.trim());
                  if (balance == null || balance < 0) {
                    return 'أدخل رصيدًا صحيحًا';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAccount,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حفظ الحساب'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
