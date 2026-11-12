import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback onSettingsChanged;
  const SettingsView({super.key, required this.onSettingsChanged});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _name = TextEditingController();
  final _currency = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final name = await db.getSetting('business_name', defaultValue: 'Goat & Fish Farming Business');
    final currency = await db.getSetting('currency', defaultValue: '₹');
    if (!mounted) return;
    setState(() {
      _name.text = name;
      _currency.text = currency;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final db = DatabaseHelper.instance;
      await db.setSetting('business_name', _name.text.trim());
      await db.setSetting('currency', _currency.text.trim().isEmpty ? '₹' : _currency.text.trim());
      widget.onSettingsChanged();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _currency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : ListView(padding: const EdgeInsets.all(16), children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _currency, decoration: const InputDecoration(labelText: 'Currency Symbol', hintText: 'e.g. ₹, AED, ৳', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            label: Text(_saving ? 'Saving...' : 'Save Settings'),
          ),
        ]),
  );
}
