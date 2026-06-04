import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../models/facility_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_formatter.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class BookingFormScreen extends StatefulWidget {
  final FacilityModel? facility;
  final BookingModel? booking;

  const BookingFormScreen({super.key, this.facility, this.booking})
    : assert(facility != null || booking != null);

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final formKey = GlobalKey<FormState>();

  final dateController = TextEditingController();
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();
  final purposeController = TextEditingController();
  final participantCountController = TextEditingController();
  final noteController = TextEditingController();

  late ConfettiController confettiController;

  DateTime? selectedDate;

  bool get isEditMode => widget.booking != null;

  String get facilityName {
    return widget.facility?.name ?? widget.booking?.facilityName ?? '-';
  }

  String get sportType {
    return widget.facility?.sportType ?? widget.booking?.sportType ?? '-';
  }

  String get campus {
    return widget.facility?.campus ?? widget.booking?.campus ?? '-';
  }

  String get imageUrl {
    return widget.facility?.imageUrl ?? '';
  }

  @override
  void initState() {
    super.initState();

    confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    if (isEditMode) {
      final booking = widget.booking!;

      selectedDate = booking.date;
      dateController.text = DateFormatter.formatShortDate(booking.date);
      startTimeController.text = booking.startTime;
      endTimeController.text = booking.endTime;
      purposeController.text = booking.purpose;
      participantCountController.text = booking.participantCount.toString();
      noteController.text = booking.note;
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    purposeController.dispose();
    participantCountController.dispose();
    noteController.dispose();
    confettiController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryDarkGreen,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    setState(() {
      selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
      dateController.text = DateFormatter.formatShortDate(pickedDate);
    });
  }

  Future<void> pickTime(TextEditingController controller) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryDarkGreen,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    final hour = pickedTime.hour.toString().padLeft(2, '0');
    final minute = pickedTime.minute.toString().padLeft(2, '0');

    controller.text = '$hour:$minute';
  }

  int timeToMinutes(String time) {
    final parts = time.split(':');

    if (parts.length != 2) {
      return 0;
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return hour * 60 + minute;
  }

  bool validateBookingTime() {
    final start = timeToMinutes(startTimeController.text);
    final end = timeToMinutes(endTimeController.text);

    if (end <= start) {
      showError('Jam selesai harus lebih besar dari jam mulai.');
      return false;
    }

    return true;
  }

  Future<void> submitBooking() async {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedDate == null) {
      showError('Tanggal booking wajib dipilih.');
      return;
    }

    if (!validateBookingTime()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();

    final user = authProvider.currentUser;

    if (user == null) {
      showError('User belum login.');
      return;
    }

    final participantCount = int.parse(participantCountController.text.trim());

    bool success = false;

    if (isEditMode) {
      final oldBooking = widget.booking!;

      final updatedBooking = oldBooking.copyWith(
        date: selectedDate,
        startTime: startTimeController.text.trim(),
        endTime: endTimeController.text.trim(),
        purpose: purposeController.text.trim(),
        participantCount: participantCount,
        note: noteController.text.trim(),
        updatedAt: DateTime.now(),
      );

      success = await bookingProvider.updateBooking(updatedBooking);
    } else {
      final facility = widget.facility!;

      final newBooking = BookingModel(
        id: '',
        userId: user.uid,
        userName: user.name,
        userNim: user.nim,
        facilityId: facility.id,
        facilityName: facility.name,
        sportType: facility.sportType,
        campus: facility.campus,
        date: selectedDate!,
        startTime: startTimeController.text.trim(),
        endTime: endTimeController.text.trim(),
        purpose: purposeController.text.trim(),
        participantCount: participantCount,
        note: noteController.text.trim(),
        status: 'pending',
        adminNote: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      success = await bookingProvider.createBooking(newBooking);
    }

    if (!mounted) return;

    if (!success) {
      showError(
        bookingProvider.errorMessage ??
            'Gagal menyimpan booking. Silakan coba lagi.',
      );
      return;
    }

    if (!isEditMode) {
      confettiController.play();
    }

    await showSuccessDialog();

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Future<void> showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.lightGreenSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEditMode
                  ? Icons.check_circle_outline
                  : Icons.event_available_outlined,
              color: AppColors.success,
              size: 34,
            ),
          ),
          title: Text(
            isEditMode ? 'Booking Diperbarui' : 'Booking Berhasil',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          content: Text(
            isEditMode
                ? 'Data booking berhasil diperbarui.'
                : 'Booking berhasil diajukan dan sedang menunggu persetujuan admin.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Form(
            key: formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  _BookingFormHeader(
                    title: isEditMode ? 'Edit Booking' : 'Booking Fasilitas',
                    subtitle: isEditMode
                        ? 'Perbarui data booking yang masih pending.'
                        : 'Lengkapi data berikut untuk mengajukan booking.',
                  ),
                  Transform.translate(
                    offset: const Offset(0, -38),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 92),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildFacilityCard(),
                          const SizedBox(height: 16),
                          buildFormCard(bookingProvider),
                          const SizedBox(height: 16),
                          const _PendingInfoBox(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 25,
            gravity: 0.2,
          ),
        ],
      ),
      bottomNavigationBar: _SubmitBar(
        isEditMode: isEditMode,
        isLoading: bookingProvider.isLoading,
        onPressed: submitBooking,
      ),
    );
  }

  Widget buildFacilityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          _FacilityThumb(imageUrl: imageUrl, sportType: sportType),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fasilitas yang Dipesan',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  facilityName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniPill(
                      icon: Icons.sports_soccer_outlined,
                      text: sportType,
                    ),
                    _MiniPill(icon: Icons.location_on_outlined, text: campus),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFormCard(BookingProvider bookingProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Pengajuan',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: dateController,
            label: 'Tanggal Booking *',
            prefixIcon: Icons.calendar_month_outlined,
            readOnly: true,
            onTap: pickDate,
            validator: (value) {
              return Validators.required(value, 'Tanggal booking');
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: startTimeController,
                  label: 'Jam Mulai *',
                  prefixIcon: Icons.access_time,
                  readOnly: true,
                  onTap: () => pickTime(startTimeController),
                  validator: (value) {
                    return Validators.time(value, 'Jam mulai');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: endTimeController,
                  label: 'Jam Selesai *',
                  prefixIcon: Icons.access_time_filled,
                  readOnly: true,
                  onTap: () => pickTime(endTimeController),
                  validator: (value) {
                    return Validators.time(value, 'Jam selesai');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: purposeController,
            label: 'Tujuan Booking *',
            hint: 'Contoh: Latihan UKM, pertandingan, kelas olahraga',
            prefixIcon: Icons.flag_outlined,
            maxLines: 2,
            validator: (value) {
              return Validators.required(value, 'Tujuan booking');
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: participantCountController,
            label: 'Jumlah Peserta *',
            prefixIcon: Icons.groups_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              return Validators.number(value, 'Jumlah peserta');
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: noteController,
            label: 'Catatan Tambahan',
            hint: 'Opsional',
            prefixIcon: Icons.notes_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _BookingFormHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BookingFormHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 70),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            bottom: -30,
            child: Icon(
              Icons.event_available_outlined,
              size: 120,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Colors.white,
                        tooltip: 'Kembali',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: AppColors.primaryDarkGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'UNESA SportHub',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityThumb extends StatelessWidget {
  final String imageUrl;
  final String sportType;

  const _FacilityThumb({required this.imageUrl, required this.sportType});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 88,
          height: 88,
          fit: BoxFit.cover,
          placeholder: (context, url) => const _ThumbFallback(),
          errorWidget: (context, url, error) => const _ThumbFallback(),
        ),
      );
    }

    return const _ThumbFallback();
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.stadium_outlined,
              color: Colors.white.withValues(alpha: 0.16),
              size: 58,
            ),
          ),
          const Center(
            child: Icon(Icons.sports_soccer, color: Colors.white, size: 38),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.lightGreenSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondaryGreen),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingInfoBox extends StatelessWidget {
  const _PendingInfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pendingSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.22)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Setiap pengajuan booking akan berstatus Pending terlebih dahulu.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final bool isEditMode;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitBar({
    required this.isEditMode,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: CustomButton(
          text: isEditMode ? 'Simpan Perubahan' : 'Ajukan Booking',
          icon: isEditMode ? Icons.save_outlined : Icons.event_available,
          isLoading: isLoading,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
