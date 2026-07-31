import 'package:driver_app/src/Core/Network/DriverOperationsClient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

class ServiceCreditsScreen extends StatefulWidget {
  const ServiceCreditsScreen({super.key});

  @override
  State<ServiceCreditsScreen> createState() => _ServiceCreditsScreenState();
}

class _ServiceCreditsScreenState extends State<ServiceCreditsScreen> {
  final _amountController = TextEditingController();
  final _senderController = TextEditingController();
  final _referenceController = TextEditingController();

  Map<String, dynamic> _status = const {};
  Map<String, dynamic> _wallet = const {};
  List<Map<String, dynamic>> _ledger = const [];
  List<Map<String, dynamic>> _channels = const [];
  List<Map<String, dynamic>> _topups = const [];
  String? _selectedChannelId;
  String? _errorMessage;
  bool _loading = true;
  bool _submitting = false;

  DriverOperationsClient get _client => Modular.get<DriverOperationsClient>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _senderController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }
    try {
      final results = await Future.wait<dynamic>([
        _client.getOperatingStatus(),
        _client.getWallet(),
        _client.getLedger(),
        _client.getTopupChannels(),
        _client.getTopups(),
      ]);
      final channels = results[3] as List<Map<String, dynamic>>;
      if (!mounted) return;
      setState(() {
        _status = results[0] as Map<String, dynamic>;
        _wallet = results[1] as Map<String, dynamic>;
        _ledger = _items(results[2]);
        _channels = channels;
        _topups = _items(results[4]);
        _selectedChannelId =
            channels.any((channel) => channel['id'] == _selectedChannelId)
            ? _selectedChannelId
            : channels.firstOrNull?['id']?.toString();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = driverOperationMessage(error);
        _loading = false;
      });
    }
  }

  Future<void> _submitTopup() async {
    final amountPesos = double.tryParse(_amountController.text.trim());
    final amountCentavos = amountPesos == null
        ? 0
        : (amountPesos * 100).round();
    if (_selectedChannelId == null) {
      _showError('Choose an available payment channel.');
      return;
    }
    if (amountCentavos < 10000 || amountCentavos > 100000) {
      _showError('Top-up amount must be between ₱100 and ₱1,000.');
      return;
    }
    if (_senderController.text.trim().length < 2) {
      _showError('Enter the sender name shown in your payment app.');
      return;
    }
    if (_referenceController.text.trim().length < 3) {
      _showError('Enter the payment transaction reference.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _client.submitTopup(
        channelId: _selectedChannelId!,
        amountCentavos: amountCentavos,
        senderName: _senderController.text.trim(),
        transactionReference: _referenceController.text.trim(),
      );
      _amountController.clear();
      _senderController.clear();
      _referenceController.clear();
      if (mounted) {
        CustomToast.show(context, 'Top-up submitted for owner verification.');
      }
      await _load();
    } catch (error) {
      _showError(driverOperationMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    if (mounted) CustomToast.show(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Service Credits',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                children: [
                  if (_errorMessage != null) _errorBanner(_errorMessage!),
                  if (_status['blockingCode'] != null)
                    _errorBanner(
                      driverOperationMessage(
                        DriverOperationException(
                          code: _status['blockingCode']?.toString(),
                          message:
                              _status['blockingMessage']?.toString() ??
                              'Your account cannot operate right now.',
                        ),
                      ),
                    ),
                  _walletCard(),
                  const SizedBox(height: 24),
                  _sectionTitle('Request a top-up'),
                  const SizedBox(height: 10),
                  _topupForm(),
                  const SizedBox(height: 24),
                  _sectionTitle('Top-up history'),
                  const SizedBox(height: 10),
                  if (_topups.isEmpty)
                    _emptyCard('No top-up requests yet.')
                  else
                    ..._topups.map(_topupTile),
                  const SizedBox(height: 24),
                  _sectionTitle('Credit ledger'),
                  const SizedBox(height: 10),
                  if (_ledger.isEmpty)
                    _emptyCard('No credit activity yet.')
                  else
                    ..._ledger.map(_ledgerTile),
                ],
              ),
            ),
    );
  }

  Widget _walletCard() {
    final balance = _centavos(_wallet['balanceCentavos']);
    final reserved = _centavos(_wallet['reservedCentavos']);
    final available = _centavos(_wallet['availableBalanceCentavos']);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVAILABLE CREDIT',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _php(available),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _walletValue('Purchased', balance)),
              Expanded(child: _walletValue('Reserved', reserved)),
            ],
          ),
          if (available < 10000) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    LucideIcons.triangle_alert,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Low balance. A ride can only be accepted when available credits cover its commission.',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _walletValue(String label, int amountCentavos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
          ),
        ),
        Text(
          _php(amountCentavos),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _topupForm() {
    final selectedChannel = _channels.cast<Map<String, dynamic>?>().firstWhere(
      (channel) => channel?['id'] == _selectedChannelId,
      orElse: () => null,
    );
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_channels.isEmpty)
            const Text(
              'No top-up channel is available. Ask support to configure one.',
            )
          else ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedChannelId,
              decoration: _inputDecoration('Payment channel'),
              items: _channels
                  .map(
                    (channel) => DropdownMenuItem(
                      value: channel['id']?.toString(),
                      child: Text(channel['name']?.toString() ?? 'Channel'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => setState(() => _selectedChannelId = value),
            ),
            if (selectedChannel != null) ...[
              const SizedBox(height: 12),
              Text(
                '${selectedChannel['accountName'] ?? ''}\n${selectedChannel['accountReference'] ?? ''}',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((selectedChannel['instructions']?.toString() ?? '')
                  .isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  selectedChannel['instructions'].toString(),
                  style: TextStyle(
                    color: AppTheme.primaryColor.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration('Amount in pesos (₱100–₱1,000)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senderController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('Sender name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenceController,
              decoration: _inputDecoration('Transaction reference'),
            ),
            const SizedBox(height: 12),
            Text(
              'Send payment using the channel above, then enter only the sender name and transaction reference. Never send a screenshot, wallet password, PIN, OTP, or payment credentials.',
              style: TextStyle(
                color: AppTheme.primaryColor.withValues(alpha: 0.55),
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitTopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _submitting ? 'Submitting…' : 'Submit for verification',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _topupTile(Map<String, dynamic> item) {
    final request = item['request'] is Map
        ? Map<String, dynamic>.from(item['request'] as Map)
        : item;
    return _card(
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(LucideIcons.wallet_cards),
        title: Text(
          _php(_centavos(request['amountCentavos'])),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${item['channelName'] ?? 'Payment channel'} • ${_manilaTime(request['submittedAt'])}\nReference: ${request['transactionReference'] ?? '—'}',
        ),
        trailing: _statusChip(request['status']?.toString() ?? 'pending'),
      ),
    );
  }

  Widget _ledgerTile(Map<String, dynamic> entry) {
    final balanceDelta = _signedCentavos(entry['balanceDeltaCentavos']);
    final reservedDelta = _signedCentavos(entry['reservedDeltaCentavos']);
    final changedAmount = balanceDelta != 0 ? balanceDelta : reservedDelta;
    return _card(
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          changedAmount < 0 ? LucideIcons.arrow_down : LucideIcons.arrow_up,
          color: changedAmount < 0 ? AppTheme.cancel : AppTheme.complete,
        ),
        title: Text(
          _titleCase(entry['type']?.toString() ?? 'credit'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${entry['reason'] ?? ''}\n${_manilaTime(entry['createdAt'])}',
        ),
        trailing: Text(
          '${changedAmount > 0 ? '+' : ''}${_php(changedAmount)}',
          style: TextStyle(
            color: changedAmount < 0 ? AppTheme.cancel : AppTheme.complete,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = switch (status) {
      'approved' => AppTheme.complete,
      'rejected' => AppTheme.cancel,
      _ => AppTheme.inProgress,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _titleCase(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cancel.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.circle_alert, color: AppTheme.cancel, size: 19),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) => _card(
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(color: AppTheme.primaryColor.withValues(alpha: 0.55)),
      ),
    ),
  );

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: AppTheme.primaryColor.withValues(alpha: 0.45),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static List<Map<String, dynamic>> _items(dynamic response) {
    if (response is! Map || response['items'] is! List) return const [];
    return (response['items'] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static int _centavos(dynamic value) => value is num ? value.toInt() : 0;

  static int _signedCentavos(dynamic value) => value is num ? value.toInt() : 0;

  static String _php(int centavos) {
    final sign = centavos < 0 ? '-' : '';
    return '$sign₱${(centavos.abs() / 100).toStringAsFixed(2)}';
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    final words = value.replaceAll('_', ' ').split(' ');
    return words
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  static String _manilaTime(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'Unknown time';
    final manila = parsed.toUtc().add(const Duration(hours: 8));
    String two(int part) => part.toString().padLeft(2, '0');
    return '${manila.year}-${two(manila.month)}-${two(manila.day)} '
        '${two(manila.hour)}:${two(manila.minute)} PHT';
  }
}
