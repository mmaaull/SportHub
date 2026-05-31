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

  const BookingFormScreen({
    super.key,
    this.facility,
    this.booking,
  }) : assert(facility != null || booking != null);

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

    final participantCount = int.parse(
      participantCountController.text.trim(),
    );

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            isEditMode ? 'Booking Diperbarui' : 'Booking Berhasil',
          ),
          content: Text(
            isEditMode
                ? 'Data booking berhasil diperbarui.'
                : 'Booking berhasil diajukan dan sedang menunggu persetujuan admin.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Booking' : 'Form Booking'),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  buildFacilityCard(),
                  const SizedBox(height: 18),
                  buildFormCard(bookingProvider),
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
    );
  }

  Widget buildFacilityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Icon(
                Icons.sports_soccer,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facilityName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$sportType • $campus',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFormCard(BookingProvider bookingProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CustomTextField(
              controller: dateController,
              label: 'Tanggal Booking',
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
                    label: 'Jam Mulai',
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
                    label: 'Jam Selesai',
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
              label: 'Tujuan Booking',
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
              label: 'Jumlah Peserta',
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
            const SizedBox(height: 24),
            CustomButton(
              text: isEditMode ? 'Simpan Perubahan' : 'Ajukan Booking',
              icon: isEditMode ? Icons.save : Icons.event_available,
              isLoading: bookingProvider.isLoading,
              onPressed: submitBooking,
            ),
          ],
        ),
      ),
    );
  }
}