import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../widgets/panic_button.dart';
import '../services/voice_detection_service.dart';
import '../services/contact_storage_service.dart';
import '../models/emergency_contact.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  final VoiceDetectionService _voiceService = VoiceDetectionService();
  final ContactStorageService _contactStorage = ContactStorageService();

  bool _isVoiceActive = false;
  bool _isInitializing = false;
  String _lastHeardText = '';
  String? _detectedKeyword;
  bool _isCountingDown = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;

  late AnimationController _micPulseController;
  late Animation<double> _micPulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadContacts();

    _micPulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _micPulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _micPulseController, curve: Curves.easeInOut),
    );

    // Setup voice service callbacks
    _voiceService.onEmergencyDetected = _onEmergencyKeywordDetected;
    _voiceService.onSpeechResult = (text) {
      if (mounted) {
        setState(() => _lastHeardText = text);
      }
    };
    _voiceService.onListeningStateChanged = (listening) {
      if (mounted) {
        setState(() => _isVoiceActive = listening);
        if (listening) {
          _micPulseController.repeat(reverse: true);
        } else {
          _micPulseController.stop();
          _micPulseController.reset();
        }
      }
    };
    _voiceService.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ $error'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    };
  }

  Future<void> _loadContacts() async {
    await _contactStorage.loadContacts();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _micPulseController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  // ============================================================
  // VOICE DETECTION & AUTO-CALL LOGIC
  // ============================================================

  Future<void> _toggleVoiceDetection() async {
    if (_isInitializing) return;

    setState(() => _isInitializing = true);

    try {
      if (_isVoiceActive) {
        await _voiceService.stopListening();
      } else {
        await _voiceService.startListening();
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  void _onEmergencyKeywordDetected(String keyword) {
    if (_isCountingDown) return; // Already counting down

    HapticFeedback.heavyImpact();
    setState(() {
      _detectedKeyword = keyword;
      _isCountingDown = true;
      _countdownSeconds = 5;
    });

    // Show countdown dialog
    _showCountdownDialog(keyword);
  }

  void _showCountdownDialog(String keyword) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdownSeconds--;
      });
      if (_countdownSeconds <= 0) {
        timer.cancel();
        Navigator.of(context, rootNavigator: true).pop();
        _executeEmergencyCall();
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Update countdown in dialog via parent setState
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: AppColors.danger.withOpacity(0.5), width: 2),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_rounded,
                        color: AppColors.danger, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Emergency Detected!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                      children: [
                        const TextSpan(text: 'Keyword '),
                        TextSpan(
                          text: '"$keyword"',
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' was detected.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Countdown circle
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 0.0),
                    duration: const Duration(seconds: 5),
                    builder: (context, value, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 6,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.danger),
                            ),
                          ),
                          Text(
                            '$_countdownSeconds',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Calling emergency contact in $_countdownSeconds seconds...',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _cancelCountdown();
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('CANCEL — I\'m Safe',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    setState(() {
      _isCountingDown = false;
      _detectedKeyword = null;
      _countdownSeconds = 5;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Emergency cancelled — stay safe!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _executeEmergencyCall() async {
    setState(() {
      _isCountingDown = false;
      _detectedKeyword = null;
      _countdownSeconds = 5;
    });

    final primaryContact = _contactStorage.getPrimaryContact();

    if (primaryContact != null) {
      // Use flutter_phone_direct_caller for instant direct call
      try {
        await FlutterPhoneDirectCaller.callNumber(primaryContact.phoneNumber);
        print('📞 Auto-calling: ${primaryContact.name} (${primaryContact.phoneNumber})');
      } catch (e) {
        // Fallback to url_launcher
        final uri = Uri.parse('tel:${primaryContact.phoneNumber}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } else {
      // No contacts — call 112 (India emergency)
      try {
        await FlutterPhoneDirectCaller.callNumber('112');
      } catch (e) {
        final uri = Uri.parse('tel:112');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No contacts saved — calling 112'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  // ============================================================
  // CONTACT MANAGEMENT
  // ============================================================

  void _showAddContactDialog({EmergencyContact? existingContact}) {
    final nameController =
        TextEditingController(text: existingContact?.name ?? '');
    final phoneController =
        TextEditingController(text: existingContact?.phoneNumber ?? '');
    final relationController =
        TextEditingController(text: existingContact?.relationship ?? '');
    bool isPrimary = existingContact?.isPrimary ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existingContact == null ? 'Add Emergency Contact' : 'Edit Contact',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_rounded),
                    hintText: '+91XXXXXXXXXX',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: relationController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.group_rounded),
                    hintText: 'e.g. Mother, Father, Friend',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  title: const Text('Primary Contact'),
                  subtitle: const Text(
                    'Will be called first during emergency',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: isPrimary,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setDialogState(() => isPrimary = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final relation = relationController.text.trim();

                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name and phone number are required'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final contact = EmergencyContact(
                  id: existingContact?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  phoneNumber: phone,
                  relationship: relation.isEmpty ? 'Other' : relation,
                  isPrimary: isPrimary,
                );

                if (existingContact == null) {
                  await _contactStorage.addContact(contact);
                } else {
                  await _contactStorage.updateContact(contact);
                }

                if (isPrimary) {
                  await _contactStorage.setPrimaryContact(contact.id);
                }

                Navigator.pop(ctx);
                setState(() {});
              },
              child: Text(existingContact == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Contact'),
        content: Text('Remove ${contact.name} from emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _contactStorage.deleteContact(contact.id);
      setState(() {});
    }
  }

  // ============================================================
  // KEYWORD MANAGEMENT
  // ============================================================

  void _showKeywordManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final keywords = _voiceService.emergencyKeywords;
            final addController = TextEditingController();

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '🔑 Emergency Keywords',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'When any of these words are detected in your voice, an emergency call will be triggered.',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),

                  // Add keyword field
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addController,
                          decoration: const InputDecoration(
                            hintText: 'Add new keyword...',
                            prefixIcon: Icon(Icons.add_rounded),
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (val) async {
                            if (val.trim().isNotEmpty) {
                              await _voiceService
                                  .addEmergencyKeyword(val.trim());
                              addController.clear();
                              setSheetState(() {});
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final val = addController.text.trim();
                          if (val.isNotEmpty) {
                            await _voiceService.addEmergencyKeyword(val);
                            addController.clear();
                            setSheetState(() {});
                            setState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Keywords list
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: keywords.map((keyword) {
                      return Chip(
                        label: Text(
                          keyword,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500),
                        ),
                        backgroundColor:
                            AppColors.primary.withOpacity(0.1),
                        side: BorderSide(
                            color: AppColors.primary.withOpacity(0.3)),
                        deleteIcon: const Icon(Icons.close_rounded,
                            size: 18),
                        onDeleted: () async {
                          await _voiceService
                              .removeEmergencyKeyword(keyword);
                          setSheetState(() {});
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // MANUAL EMERGENCY TRIGGER
  // ============================================================

  void _triggerEmergency() {
    _onEmergencyKeywordDetected('manual SOS');
  }

  // ============================================================
  // BUILD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final contacts = _contactStorage.contacts;
    final primaryContact = _contactStorage.getPrimaryContact();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Manage Keywords',
            onPressed: _showKeywordManager,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add Contact',
            onPressed: () => _showAddContactDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================
            // VOICE DETECTION CARD
            // =====================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isVoiceActive
                      ? [
                          const Color(0xFF1B5E20),
                          const Color(0xFF2E7D32),
                        ]
                      : [
                          const Color(0xFF1A1A2E),
                          const Color(0xFF16213E),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_isVoiceActive
                            ? AppColors.success
                            : AppColors.primary)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Mic button
                  GestureDetector(
                    onTap: _isInitializing ? null : _toggleVoiceDetection,
                    child: AnimatedBuilder(
                      animation: _micPulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isVoiceActive
                              ? _micPulseAnimation.value
                              : 1.0,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isVoiceActive
                                  ? AppColors.success
                                  : Colors.white24,
                              boxShadow: _isVoiceActive
                                  ? [
                                      BoxShadow(
                                        color:
                                            AppColors.success.withOpacity(0.5),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: _isInitializing
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 3),
                                  )
                                : Icon(
                                    _isVoiceActive
                                        ? Icons.mic_rounded
                                        : Icons.mic_off_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isVoiceActive
                        ? '🎤 Listening for Keywords...'
                        : 'Tap to Start Voice Detection',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_isVoiceActive && _lastHeardText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hearing_rounded,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '"$_lastHeardText"',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Keyword chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: _voiceService.emergencyKeywords.map((kw) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          kw,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // =====================
            // PANIC BUTTON
            // =====================
            Center(
              child: PanicButton(
                size: 140,
                onPressed: _triggerEmergency,
              ),
            ),
            const SizedBox(height: 28),

            // =====================
            // QUICK ACTIONS
            // =====================
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.phone_rounded,
                    label: 'Call 112',
                    color: AppColors.danger,
                    onTap: () async {
                      try {
                        await FlutterPhoneDirectCaller.callNumber('112');
                      } catch (e) {
                        final uri = Uri.parse('tel:112');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.record_voice_over_rounded,
                    label: 'Keywords',
                    color: AppColors.info,
                    onTap: _showKeywordManager,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // =====================
            // EMERGENCY CONTACTS
            // =====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emergency Contacts',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                TextButton.icon(
                  onPressed: () => _showAddContactDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (primaryContact != null)
              Text(
                'Primary: ${primaryContact.name} — will be auto-called on keyword detection',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            const SizedBox(height: 12),

            if (contacts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.person_add_rounded,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No emergency contacts added yet',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add contacts who will be called automatically\nwhen an emergency keyword is detected',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddContactDialog(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Contact'),
                    ),
                  ],
                ),
              )
            else
              ...contacts.map((contact) => _buildContactCard(contact)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: contact.isPrimary
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.15),
              radius: 24,
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            if (contact.isPrimary)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (contact.isPrimary)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PRIMARY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text('${contact.relationship} • ${contact.phoneNumber}'),
        trailing: PopupMenuButton<String>(
          icon:
              const Icon(Icons.more_vert_rounded, color: AppColors.textTertiary),
          onSelected: (value) async {
            switch (value) {
              case 'call':
                try {
                  await FlutterPhoneDirectCaller.callNumber(
                      contact.phoneNumber);
                } catch (e) {
                  final uri = Uri.parse('tel:${contact.phoneNumber}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                }
                break;
              case 'primary':
                await _contactStorage.setPrimaryContact(contact.id);
                setState(() {});
                break;
              case 'edit':
                _showAddContactDialog(existingContact: contact);
                break;
              case 'delete':
                await _deleteContact(contact);
                break;
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
                value: 'call',
                child: ListTile(
                    leading: Icon(Icons.phone_rounded),
                    title: Text('Call Now'))),
            const PopupMenuItem(
                value: 'primary',
                child: ListTile(
                    leading: Icon(Icons.star_rounded),
                    title: Text('Set as Primary'))),
            const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                    leading: Icon(Icons.edit_rounded),
                    title: Text('Edit'))),
            const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    leading: Icon(Icons.delete_rounded, color: AppColors.error),
                    title:
                        Text('Delete', style: TextStyle(color: AppColors.error)))),
          ],
        ),
      ),
    );
  }
}
