import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:porter_clone_user/core/services/trip_api_service.dart';
import 'package:porter_clone_user/core/storage/auth_local_storage.dart';
import 'package:porter_clone_user/features/map/view/map_picker_page.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const Color _pageBg = Color(0xFFf4f4f4);
const Color _fieldBg = Color(0xFFffffff);
const Color _fieldBorder = Color(0xFFEDF1F3);
const Color _hintColor = Color(0xFFA2A2A2);
const Color _labelColor = Color(0xFF000000);
const Color _titleColor = Color(0xFF000000);
const Color _progressBlack = Color(0xFF000000);
const Color _progressGrey = Color(0xFFE8E9F1);
const Color _pinRed = Color(0xFFDE4B65);

BoxDecoration _fieldDecoration() => BoxDecoration(
  color: _fieldBg,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: _fieldBorder, width: 1),
);

class _TripChoice {
  const _TripChoice({required this.value, required this.label});

  final String value;
  final String label;
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  int _step = 0;
  final TripApiService _tripApiService = const TripApiService();

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  final List<TextEditingController> _stopControllers = [];

  // Store coordinates for pickup and drop locations
  double? _pickupLat;
  double? _pickupLng;
  double? _dropLat;
  double? _dropLng;

  List<_TripChoice> _loadSizeChoices = const [];
  List<_TripChoice> _bodyTypeChoices = const [];
  List<_TripChoice> _loadTypeChoices = const [];
  List<_TripChoice> _toneChoices = const [];

  String? _bodyType;
  String? _loadType;
  String? _loadSize;
  String? _tone;
  TimeOfDay? _startTime;
  DateTime? _pickupDate;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _receiverNumberController =
      TextEditingController();

  bool _isSubmitting = false;

  void _resetForm() {
    setState(() {
      _step = 0;
      _pickupController.clear();
      _dropController.clear();
      _stopControllers.clear();
      _pickupLat = null;
      _pickupLng = null;
      _dropLat = null;
      _dropLng = null;
      _loadSize = null;
      _bodyType = null;
      _loadType = null;
      _tone = null;
      _startTime = null;
      _pickupDate = null;
      _amountController.clear();
      _ownerNameController.clear();
      _contactNumberController.clear();
      _receiverNumberController.clear();
    });
  }

  void _next() {
    final error = _validateTripDetails();
    if (error != null) {
      _showMessage(error);
      return;
    }
    if (_step < 1) {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  static const _titles = ['Trip Details', 'Trip Details'];
  static const _progress = [0.50, 1.0];

  @override
  void initState() {
    super.initState();
    _fetchChoices();
  }

  Future<void> _fetchChoices() async {
    try {
      final response = await _tripApiService.getTripChoices();
      if (!mounted) {
        return;
      }

      setState(() {
        _loadSizeChoices = _parseChoices(response['load_size']);
        _bodyTypeChoices = _parseChoices(response['body_type']);
        _loadTypeChoices = _parseChoices(response['load_type']);
        _toneChoices = _parseChoices(response['vehicle_size']);
      });

      debugPrint(
        'Trip choices loaded: '
        'load_size=${_loadSizeChoices.length}, '
        'body_type=${_bodyTypeChoices.length}, '
        'load_type=${_loadTypeChoices.length}, '
        'tone=${_toneChoices.length}',
      );
    } catch (error) {
      debugPrint('Trip choices API error: $error');
    }
  }

  List<_TripChoice> _parseChoices(dynamic source) {
    if (source is! List) {
      return const <_TripChoice>[];
    }

    return source
        .map<_TripChoice?>((entry) {
          if (entry is! Map) {
            return null;
          }

          final value = entry['value']?.toString().trim() ?? '';
          final label = entry['label']?.toString().trim() ?? value;
          if (value.isEmpty) {
            return null;
          }

          return _TripChoice(
            value: value,
            label: label.isEmpty ? value : label,
          );
        })
        .whereType<_TripChoice>()
        .toList();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateTripDetails() {
    if (_pickupController.text.trim().isEmpty) {
      return 'Select a starting location.';
    }
    if (_dropController.text.trim().isEmpty) {
      return 'Select a destination.';
    }
    if ((_loadSize ?? '').trim().isEmpty) {
      return 'Select a load size.';
    }
    if ((_bodyType ?? '').trim().isEmpty) {
      return 'Select a body type.';
    }
    if ((_loadType ?? '').trim().isEmpty) {
      return 'Select a loading item.';
    }
    if (_startTime == null) {
      return 'Select a pickup time.';
    }
    if (_pickupDate == null) {
      return 'Select a pickup date.';
    }
    if ((_tone ?? '').trim().isEmpty) {
      return 'Select a tone.';
    }
    return null;
  }

  String? _validateOwnerDetails() {
    if (_contactNumberController.text.trim().isEmpty) {
      return 'Enter a contact number.';
    }
    return null;
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    for (final controller in _stopControllers) {
      controller.dispose();
    }
    _amountController.dispose();
    _ownerNameController.dispose();
    _contactNumberController.dispose();
    _receiverNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation({
    required TextEditingController controller,
    required String title,
  }) async {
    final picked = await MapPickerPage.pick(context, title: title);
    if (picked == null) {
      return;
    }
    controller.text = picked.label;

    // Store coordinates based on which field is being updated
    if (controller == _pickupController) {
      _pickupLat = picked.position.latitude;
      _pickupLng = picked.position.longitude;
    } else if (controller == _dropController) {
      _dropLat = picked.position.latitude;
      _dropLng = picked.position.longitude;
    }
  }

  void _addStop() {
    setState(() => _stopControllers.add(TextEditingController()));
  }

  Future<void> _pickStop(int index) async {
    if (index < 0 || index >= _stopControllers.length) {
      return;
    }
    await _pickLocation(
      controller: _stopControllers[index],
      title: 'Select stop location',
    );
  }

  List<String> _pendingStops() => _stopControllers
      .map((controller) => controller.text.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  List<String> _buildStops() => <String>[
        _pickupController.text.trim(),
        ..._pendingStops(),
        _dropController.text.trim(),
      ].where((value) => value.isNotEmpty).toList();

  String _formatPayloadTime(TimeOfDay? time) {
    if (time == null) return '';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Formats the pickup date as YYYY-MM-DD for the backend.
  String _formatPayloadDate(DateTime? date) {
    if (date == null) return '';
    final y = date.year.toString();
    final mo = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$mo-$d';
  }

  Map<String, String> _buildTripPayload() {
    final payload = <String, String>{
      'pickup_location': _pickupController.text.trim(),
      'drop_location': _dropController.text.trim(),
      'load_size': (_loadSize ?? '').trim(),
      'load_type': (_loadType ?? '').trim(),
      'start_time': _formatPayloadTime(_startTime),
      'pickup_date': _formatPayloadDate(_pickupDate),
      'body_type': (_bodyType ?? '').trim(),
      'tone': (_tone ?? '').trim(),
      'amount': _amountController.text.trim(),
      'name': _ownerNameController.text.trim(),
      'contact_number': _contactNumberController.text.trim(),
      'receiver_number': _receiverNumberController.text.trim(),
    };

    // Add coordinates if available
    if (_pickupLat != null) {
      payload['pickup_loc_lat'] = _pickupLat.toString();
    }
    if (_pickupLng != null) {
      payload['pickup_loc_lng'] = _pickupLng.toString();
    }
    if (_dropLat != null) {
      payload['drop_loc_lat'] = _dropLat.toString();
    }
    if (_dropLng != null) {
      payload['drop_loc_lng'] = _dropLng.toString();
    }

    // Only include stops if user explicitly added intermediate stops
    final pendingStops = _pendingStops();
    if (pendingStops.isNotEmpty) {
      final allStops = <String>[
        _pickupController.text.trim(),
        ...pendingStops,
        _dropController.text.trim(),
      ].where((value) => value.isNotEmpty).toList();
      payload['stops'] = jsonEncode(allStops);
    }

    return payload;
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final tripError = _validateTripDetails();
    if (tripError != null) {
      if (_step != 0) {
        setState(() => _step = 0);
      }
      _showMessage(tripError);
      return;
    }

    final ownerError = _validateOwnerDetails();
    if (ownerError != null) {
      _showMessage(ownerError);
      return;
    }

    setState(() => _isSubmitting = true);
    final payload = _buildTripPayload();
    final stopsPending = _pendingStops();

    // Print the final payload to console
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('FINAL TRIP PAYLOAD:');
    debugPrint('═══════════════════════════════════════════════════════');
    payload.forEach((key, value) {
      debugPrint('  $key: $value');
    });
    if (stopsPending.isNotEmpty) {
      debugPrint('  stops_pending: ${jsonEncode(stopsPending)}');
    }
    debugPrint('═══════════════════════════════════════════════════════');

    try {
      final accessToken = await AuthLocalStorage.getAccessToken();
      await _tripApiService.postTrip(
        payload: payload,
        accessToken: accessToken,
        stopsPending: stopsPending,
      );
      if (!mounted) {
        return;
      }
      final shouldNavigate = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.75),
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Trip Posted',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your trip has been posted successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D1117),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (!mounted) {
        return;
      }
      if (shouldNavigate == true) {
        if (Navigator.canPop(context)) {
          // It was pushed (e.g. from the 'Create Trip' card)
          Navigator.pop(context);
        } else {
          // It's the bottom tab. Reset the form and switch tab if callback provided.
          _resetForm();
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }
        }
      }
    } on TripApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Failed to submit trip.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hp = sw * 0.055;

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hp, sh * 0.025, hp, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _titles[_step],
                          style: const TextStyle(
                            color: _titleColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      // Bell + red dot
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications,
                            color: _titleColor,
                            size: 26,
                          ),
                          Positioned(
                            top: 1,
                            right: 1,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: _pinRed,
                                shape: BoxShape.circle,
                                border: Border.all(color: _pageBg, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // GPS icon in circle
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF888888),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.gps_fixed,
                          color: _titleColor,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Animated progress bar
                  _ProgressBar(progress: _progress[_step]),
                  SizedBox(height: 20),
                ],
              ),
            ),

            SizedBox(height: sh * 0.025),

            // ── Scrollable body ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hp),
                physics: const ClampingScrollPhysics(),
                // FIX: replaced IndexedStack with a conditional so only the
                // active tab is in the widget tree, eliminating phantom overflow.
                child: _step == 0
                    ? _TripDetailsTab(
                        onNext: _next,
                        pickupController: _pickupController,
                        dropController: _dropController,
                        onPickStart: () => _pickLocation(
                          controller: _pickupController,
                          title: 'Select starting location',
                        ),
                        onPickDrop: () => _pickLocation(
                          controller: _dropController,
                          title: 'Select destination',
                        ),
                        stopControllers: _stopControllers,
                        onAddStop: _addStop,
                        onPickStop: _pickStop,
                        sizeValue: _loadSize,
                        onSizeChanged: (value) =>
                            setState(() => _loadSize = value),
                        bodyType: _bodyType,
                        onBodyTypeChanged: (value) =>
                            setState(() => _bodyType = value),
                        loadType: _loadType,
                        onLoadTypeChanged: (value) =>
                            setState(() => _loadType = value),
                        toneValue: _tone,
                        onToneChanged: (value) =>
                            setState(() => _tone = value),
                        startTime: _startTime,
                        onStartTimeChanged: (value) =>
                            setState(() => _startTime = value),
                        pickupDate: _pickupDate,
                        onPickupDateChanged: (value) =>
                            setState(() => _pickupDate = value),
                        loadTypeOptions: _loadTypeChoices,
                        sizeOptions: _loadSizeChoices,
                        bodyTypeOptions: _bodyTypeChoices,
                        toneOptions: _toneChoices,
                      )
                    : _OwnerDetailsTab(
                        onBack: _back,
                        isSubmitting: _isSubmitting,
                        onSubmit: _submit,
                        amountController: _amountController,
                        nameController: _ownerNameController,
                        contactNumberController: _contactNumberController,
                        receiverNumberController: _receiverNumberController,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Bar
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: _progressGrey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  color: _progressBlack,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Trip Details
// ─────────────────────────────────────────────────────────────────────────────
class _TripDetailsTab extends StatelessWidget {
  const _TripDetailsTab({
    required this.onNext,
    required this.pickupController,
    required this.dropController,
    required this.onPickStart,
    required this.onPickDrop,
    required this.stopControllers,
    required this.onAddStop,
    required this.onPickStop,
    required this.sizeValue,
    required this.onSizeChanged,
    required this.bodyType,
    required this.onBodyTypeChanged,
    required this.loadType,
    required this.onLoadTypeChanged,
    required this.toneValue,
    required this.onToneChanged,
    required this.startTime,
    required this.onStartTimeChanged,
    required this.pickupDate,
    required this.onPickupDateChanged,
    required this.loadTypeOptions,
    required this.sizeOptions,
    required this.bodyTypeOptions,
    required this.toneOptions,
  });
  final VoidCallback onNext;
  final TextEditingController pickupController;
  final TextEditingController dropController;
  final VoidCallback onPickStart;
  final VoidCallback onPickDrop;
  final List<TextEditingController> stopControllers;
  final VoidCallback onAddStop;
  final void Function(int) onPickStop;
  final String? sizeValue;
  final ValueChanged<String> onSizeChanged;
  final String? bodyType;
  final ValueChanged<String> onBodyTypeChanged;
  final String? loadType;
  final ValueChanged<String> onLoadTypeChanged;
  final String? toneValue;
  final ValueChanged<String> onToneChanged;
  final TimeOfDay? startTime;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final DateTime? pickupDate;
  final ValueChanged<DateTime> onPickupDateChanged;
  final List<_TripChoice> loadTypeOptions;
  final List<_TripChoice> sizeOptions;
  final List<_TripChoice> bodyTypeOptions;
  final List<_TripChoice> toneOptions;

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your destinations',
          style: TextStyle(
            color: _labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 7),

        // Location fields with dotted connector between pin icons
        _LocationFieldsWithConnector(
          startHint: 'Enter starting location',
          destinationHint: 'Enter destination',
          startController: pickupController,
          destinationController: dropController,
          onStartTap: onPickStart,
          onDestinationTap: onPickDrop,
        ),

        const SizedBox(height: 10),
        _AddStopButton(onPressed: onAddStop),
        if (stopControllers.isNotEmpty) const SizedBox(height: 10),
        ...stopControllers.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LocationField(
              hint: 'Select stop ${entry.key + 1}',
              controller: entry.value,
              onTap: () => onPickStop(entry.key),
            ),
          ),
        ),

        SizedBox(height: sh * 0.022),

        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Size (Length)',
                child: _CustomDropdown(
                  hint: 'Select size',
                  options: sizeOptions,
                  value: sizeValue,
                  onChanged: onSizeChanged,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Body Type',
                child: _CustomDropdown(
                  hint: 'Common',
                  options: bodyTypeOptions,
                  value: bodyType,
                  onChanged: onBodyTypeChanged,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: sh * 0.022),

        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Pickup time',
                child: _TimeField(
                  value: startTime,
                  onChanged: onStartTimeChanged,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Pickup date',
                child: _DateField(
                  value: pickupDate,
                  onChanged: onPickupDateChanged,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: sh * 0.022),

        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Loading item',
                child: _CustomDropdown(
                  hint: 'Select your load',
                  options: loadTypeOptions,
                  value: loadType,
                  onChanged: onLoadTypeChanged,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Tone',
                child: _CustomDropdown(
                  hint: 'Select your tone',
                  options: toneOptions,
                  value: toneValue,
                  onChanged: onToneChanged,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: sh * 0.05),

        _PrimaryButton(text: 'Next Step', onPressed: onNext),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Owner Details
// ─────────────────────────────────────────────────────────────────────────────
class _OwnerDetailsTab extends StatelessWidget {
  const _OwnerDetailsTab({
    required this.onBack,
    required this.onSubmit,
    required this.isSubmitting,
    required this.amountController,
    required this.nameController,
    required this.contactNumberController,
    required this.receiverNumberController,
  });
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final TextEditingController amountController;
  final TextEditingController nameController;
  final TextEditingController contactNumberController;
  final TextEditingController receiverNumberController;

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabeledField(
          label: 'Amount',
          child: _CustomTextField(
            hint: 'Enter amount',
            controller: amountController,
            keyboardType: TextInputType.number,
          ),
        ),

        SizedBox(height: sh * 0.022),

        _LabeledField(
          label: 'Name',
          child: _CustomTextField(
            hint: 'Enter your name',
            controller: nameController,
          ),
        ),

        SizedBox(height: sh * 0.022),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Contact Number ',
                    style: TextStyle(
                      color: _labelColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: _pinRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _CustomTextField(
              hint: '+91',
              controller: contactNumberController,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),

        SizedBox(height: sh * 0.022),

        _LabeledField(
          label: 'Receiver Number',
          child: _CustomTextField(
            hint: '+91',
            controller: receiverNumberController,
            keyboardType: TextInputType.phone,
          ),
        ),

        SizedBox(height: sh * 0.07),

        Row(
          children: [
            Expanded(
              child: _OutlineButton(text: 'Go Back', onPressed: onBack),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PrimaryButton(
                text: isSubmitting ? 'Posting...' : 'Submit',
                onPressed: isSubmitting ? null : onSubmit,
                isLoading: isSubmitting,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: _labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class _AddStopButton extends StatelessWidget {
  const _AddStopButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 46,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF111827),
        side: const BorderSide(color: _fieldBorder, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text(
        'Add stop',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _CustomTextField extends StatelessWidget {
  const _CustomTextField({
    required this.hint,
    this.controller,
    this.keyboardType,
  });
  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: _fieldDecoration(),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Color(0xFF222222),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        hintText: hint,
        hintStyle: const TextStyle(
          color: _hintColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    ),
  );
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.hint,
    required this.controller,
    this.onTap,
  });
  final String hint;
  final TextEditingController controller;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: _fieldDecoration(),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            style: const TextStyle(
              color: Color(0xFF222222),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: const TextStyle(
                color: _hintColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.map_outlined, color: _hintColor, size: 18),
      ],
    ),
  );
}

class _LocationFieldsWithConnector extends StatelessWidget {
  const _LocationFieldsWithConnector({
    required this.startHint,
    required this.destinationHint,
    required this.startController,
    required this.destinationController,
    required this.onStartTap,
    required this.onDestinationTap,
  });
  final String startHint;
  final String destinationHint;
  final TextEditingController startController;
  final TextEditingController destinationController;
  final VoidCallback onStartTap;
  final VoidCallback onDestinationTap;

  static const double _fieldHeight = 50;
  static const double _fieldGap = 18;
  static const double _avatarRadius = 20;
  static const double _avatarDiameter = _avatarRadius * 2;

  @override
  Widget build(BuildContext context) {
    final double connectorHeight =
        _fieldHeight + _fieldGap - _avatarDiameter + 5;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _LocationField(
                hint: startHint,
                controller: startController,
                onTap: onStartTap,
              ),
              const SizedBox(height: _fieldGap),
              _LocationField(
                hint: destinationHint,
                controller: destinationController,
                onTap: onDestinationTap,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: _avatarDiameter,
          height: (_fieldHeight * 2) + _fieldGap,
          child: Column(
            children: [
              const _LocationPinAvatar(radius: _avatarRadius),
              SizedBox(
                width: _avatarDiameter,
                height: connectorHeight,
                child: const CustomPaint(painter: _DottedLinePainter()),
              ),
              const _LocationPinAvatar(radius: _avatarRadius),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationPinAvatar extends StatelessWidget {
  const _LocationPinAvatar({required this.radius});
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xFFFFFFFF),
    child: const Icon(Icons.location_on_rounded, color: _pinRed, size: 24),
  );
}

class _CustomDropdown extends StatelessWidget {
  const _CustomDropdown({
    required this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final String hint;
  final List<_TripChoice> options;
  final String? value;
  final ValueChanged<String> onChanged;

  String? _selectedLabel() {
    final selectedValue = value;
    if (selectedValue == null) {
      return null;
    }

    for (final option in options) {
      if (option.value == selectedValue) {
        return option.label;
      }
    }

    return selectedValue;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 50,
    child: LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: _fieldDecoration(),
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            color: Colors.white,
            position: PopupMenuPosition.under,
            offset: const Offset(0, 6),
            initialValue: value,
            menuPadding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth,
            ),
            onSelected: onChanged,
            itemBuilder: (context) {
              return options
                  .map(
                    (option) => PopupMenuItem<String>(
                      value: option.value,
                      child: Text(
                        option.label,
                        style: const TextStyle(
                          color: Color(0xFF222222),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedLabel() ?? hint,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: value == null
                            ? _hintColor
                            : const Color(0xFF222222),
                        fontSize: 13,
                        fontWeight: value == null
                            ? FontWeight.w400
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF333333),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.value,
    required this.onChanged,
    this.hint = 'Select time',
  });
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;
  final String hint;

  String _formatDisplay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'am' : 'pm';
    return '$hour:$minute $suffix';
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF0D1117),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF222222),
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: _pageBg,
              dialBackgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) {
      return;
    }
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _pick(context),
    child: Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _fieldDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value == null ? hint : _formatDisplay(value!),
              style: TextStyle(
                color: value == null ? _hintColor : const Color(0xFF222222),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const Icon(
            Icons.access_time_outlined,
            color: Color(0xFF444444),
            size: 18,
          ),
        ],
      ),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.onChanged,
    this.hint = 'Select date',
  });
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String hint;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDisplay(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = _months[date.month - 1];
    final y = date.year;
    return '$d $m $y';
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF0D1117),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF222222),
            ),
            dialogBackgroundColor: _pageBg,
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _pick(context),
    child: Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _fieldDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value == null ? hint : _formatDisplay(value!),
              style: TextStyle(
                color: value == null ? _hintColor : const Color(0xFF222222),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const Icon(
            Icons.calendar_today_outlined,
            color: Color(0xFF444444),
            size: 18,
          ),
        ],
      ),
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                // FIX: ellipsis prevents the loading text from overflowing
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
    ),
  );
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.text, required this.onPressed});
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF111827),
        side: const BorderSide(color: Color(0xFF111827), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA7A7A7)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;
    const dash = 5.0, gap = 6.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + dash),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}