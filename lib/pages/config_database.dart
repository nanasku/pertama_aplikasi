import 'package:flutter/material.dart';
import '../services/config_service.dart';

class ConfigDatabasePage extends StatefulWidget {
  const ConfigDatabasePage({super.key});

  @override
  _ConfigDatabasePageState createState() => _ConfigDatabasePageState();
}

class _ConfigDatabasePageState extends State<ConfigDatabasePage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isTesting = false;
  bool _isSaving = false;
  String _testResult = '';
  bool _testSuccess = false;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    final currentUrl = await ConfigService.getDisplayUrl();
    setState(() {
      _currentUrl = currentUrl;
      _urlController.text = currentUrl;
    });
  }

  Future<void> _testConnection() async {
    if (_urlController.text.isEmpty) {
      setState(() {
        _testResult = 'URL tidak boleh kosong';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = '';
    });

    final testUrl = _urlController.text.trim();
    final result = await ConfigService.testConnection(testUrl);

    setState(() {
      _isTesting = false;
      _testSuccess = result['success'] ?? false;
      _testResult = result['message'] ?? 'Terjadi kesalahan saat testing';
    });
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      final url = _urlController.text.trim();
      await ConfigService.saveApiUrl(url);

      final newUrl = await ConfigService.getDisplayUrl();

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _currentUrl = newUrl;
      });

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfigurasi berhasil disimpan!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetToDefault() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Konfigurasi'),
        content: const Text(
          'Apakah Anda yakin ingin mereset ke konfigurasi default?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ConfigService.resetToDefault();
      await _loadCurrentConfig();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfigurasi direset ke default!'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfigurasi Database'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Configuration Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Konfigurasi Saat Ini',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentUrl,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Configuration Form
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ubah Konfigurasi Server',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              labelText: 'URL Server',
                              hintText: '192.168.1.40:3000',
                              prefixIcon: Icon(Icons.http),
                              border: OutlineInputBorder(),
                              helperText:
                                  'Contoh: 192.168.1.40:3000 atau localhost:3000',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'URL server tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Test Connection Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering),
                      label: Text(
                        _isTesting ? 'Menguji Koneksi...' : 'Test Koneksi',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Test Result
                  if (_testResult.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _testSuccess ? Colors.green[50] : Colors.red[50],
                        border: Border.all(
                          color: _testSuccess ? Colors.green : Colors.red,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _testSuccess ? Icons.check_circle : Icons.error,
                            color: _testSuccess ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _testResult,
                              style: TextStyle(
                                color: _testSuccess ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 30),

                  // Action Buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_isSaving || !_testSuccess)
                              ? null
                              : _saveConfig,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _isSaving ? 'Menyimpan...' : 'Simpan Konfigurasi',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _testSuccess
                                ? Colors.green
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _resetToDefault,
                          icon: const Icon(Icons.restore),
                          label: const Text('Reset ke Default'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
