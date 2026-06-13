import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/registration_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/registration_service.dart';
import '../../core/constants/app_colors.dart';

class TicketValidatorScreen extends StatefulWidget {
  const TicketValidatorScreen({super.key});

  @override
  State<TicketValidatorScreen> createState() => _TicketValidatorScreenState();
}

class _TicketValidatorScreenState extends State<TicketValidatorScreen> {
  final _controller = TextEditingController();
  final _service = RegistrationService();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  _ValidationResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final reg = await _service.validateTicket(code);
      setState(() {
        _result = reg != null
            ? _ValidationResult.valid(reg)
            : _ValidationResult.invalid();
      });
    } catch (_) {
      setState(() => _result = _ValidationResult.invalid());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _reset() {
    _controller.clear();
    setState(() => _result = null);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 24, 24, 32),
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_available_rounded,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    const Text(
                      'EventHub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        await auth.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.white70, size: 18),
                      label: const Text('Çıkış',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bilet Kontrolü',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Katılımcının bilet kodunu girin',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Input
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(8),
                      _UpperCaseFormatter(),
                    ],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'XXXXXXXX',
                      hintStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                    ),
                    onSubmitted: (_) => _validate(),
                  ),
                  const SizedBox(height: 16),

                  // Validate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'KONTROL ET',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Result
                  if (_result != null) ...[
                    _result!.isValid
                        ? _ValidResult(
                            registration: _result!.registration!,
                            onReset: _reset,
                          )
                        : _InvalidResult(onReset: _reset),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationResult {
  final bool isValid;
  final RegistrationModel? registration;

  _ValidationResult.valid(this.registration) : isValid = true;
  _ValidationResult.invalid()
      : isValid = false,
        registration = null;
}

class _ValidResult extends StatelessWidget {
  final RegistrationModel registration;
  final VoidCallback onReset;

  const _ValidResult({required this.registration, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final r = registration;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.success.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 52),
          ),
          const SizedBox(height: 16),
          const Text(
            'GEÇERLİ BİLET',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _InfoRow(
              icon: Icons.person_rounded,
              label: 'Katılımcı',
              value: r.userName),
          const SizedBox(height: 10),
          _InfoRow(
              icon: Icons.event_rounded,
              label: 'Etkinlik',
              value: r.eventTitle),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Tarih',
            value: DateFormat('d MMMM yyyy, HH:mm', 'tr_TR')
                .format(r.eventDate),
          ),
          const SizedBox(height: 10),
          _InfoRow(
              icon: Icons.location_on_rounded,
              label: 'Konum',
              value: r.eventLocation),
          const SizedBox(height: 10),
          _InfoRow(
              icon: Icons.confirmation_number_rounded,
              label: 'Bilet Kodu',
              value: r.ticketCode),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Yeni Kontrol'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.success,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvalidResult extends StatelessWidget {
  final VoidCallback onReset;
  const _InvalidResult({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.error.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_rounded,
                color: AppColors.error, size: 52),
          ),
          const SizedBox(height: 16),
          const Text(
            'GEÇERSİZ BİLET',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu bilet kodu sistemde bulunamadı\nveya iptal edilmiş.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar Dene'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.success),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            Text(value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
          ],
        ),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
