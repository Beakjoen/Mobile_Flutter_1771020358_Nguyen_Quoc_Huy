import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/booking.dart';
import '../models/court.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';

class BookingScreen extends StatefulWidget {
  final bool embedded;

  const BookingScreen({super.key, this.embedded = false});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiService _apiService = ApiService();
  List<Booking> _bookings = [];
  List<Court> _courts = [];
  bool _isLoading = true;
  CalendarView _calendarView = CalendarView.week;
  StreamSubscription<String>? _calendarUpdateSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _calendarUpdateSub = SignalRService().calendarUpdateStream.listen((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _calendarUpdateSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 7));
      final to = now.add(const Duration(days: 30));

      final courtsRes = await _apiService.getCourts();
      final bookingsRes = await _apiService.getCalendar(from, to);

      if (mounted) {
        setState(() {
          _courts = (courtsRes.data as List).map((e) => Court.fromJson(e)).toList();
          _bookings = (bookingsRes.data as List).map((e) => Booking.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createBooking(int courtId, DateTime start, DateTime end) async {
    try {
      await _apiService.createBooking(courtId, start, end);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt sân thành công!')));
      Provider.of<UserProvider>(context, listen: false).loadUser();
      _loadData();
    } on DioException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      final msg = e.response?.data?['message'] ?? e.response?.data?.toString() ?? e.message ?? '$e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _onCalendarTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.calendarCell) {
      final DateTime date = details.date!;
      final DateTime start = date;
      final DateTime end = date.add(const Duration(hours: 1));
      _showBookingDialog(start, end);
    } else if (details.targetElement == CalendarElement.appointment && details.appointments != null && details.appointments!.isNotEmpty) {
      final Booking booking = details.appointments!.first;
      _showBookingDetails(booking);
    }
  }

  void _showBookingDialog(DateTime start, DateTime end) {
    Court? selectedCourt = _courts.isNotEmpty ? _courts.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final price = selectedCourt?.pricePerHour ?? 0.0;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Đặt sân mới', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Court>(
                    value: selectedCourt,
                    decoration: const InputDecoration(labelText: 'Chọn sân'),
                    items: _courts.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: (val) => setModalState(() => selectedCourt = val),
                  ),
                  const SizedBox(height: 16),
                  Text('Thời gian: ${DateFormat('dd/MM HH:mm').format(start)} – ${DateFormat('HH:mm').format(end)}'),
                  const SizedBox(height: 8),
                  Text('Giá dự kiến: ${price.toStringAsFixed(0)} đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedCourt != null) _createBooking(selectedCourt!.id, start, end);
                      },
                      child: const Text('Xác nhận đặt sân'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBookingDetails(Booking booking) {
    final user = Provider.of<UserProvider>(context, listen: false).member;
    final isMyBooking = user != null && booking.memberId == user.id;
    final canCancel = isMyBooking && booking.status == 1; // Đã xác nhận mới được hủy
    final screenContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Chi tiết đặt sân #${booking.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sân: ${booking.court?.name ?? "—"}'),
            Text('Người đặt: ${booking.member?.fullName ?? "—"}'),
            Text('Thời gian: ${DateFormat('dd/MM HH:mm').format(booking.startTime)}'),
            Text('Trạng thái: ${booking.status == 1 ? "Đã xác nhận" : (booking.status == 2 ? "Đã hủy" : "Chờ/Hủy")}'),
          ],
        ),
        actions: [
          if (canCancel)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final ok = await showDialog<bool>(
                  context: screenContext,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xác nhận hủy'),
                    content: const Text('Bạn có chắc muốn hủy đặt sân này? Tiền sẽ được hoàn theo chính sách.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hủy đặt sân', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (ok != true || !mounted) return;
                try {
                  await _apiService.cancelBookingByPost(booking.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(screenContext).showSnackBar(const SnackBar(content: Text('Đã hủy đặt sân. Tiền sẽ được hoàn vào ví.')));
                  Provider.of<UserProvider>(screenContext, listen: false).loadUser();
                  _loadData();
                } on DioException catch (e) {
                  if (!mounted) return;
                  final msg = e.response?.data?['message'] ?? e.response?.data?.toString() ?? e.message ?? '${e.message}';
                  ScaffoldMessenger.of(screenContext).showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(screenContext).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              },
              child: const Text('Hủy đặt sân', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _buildColorLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  void _showRecurringBookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _RecurringBookingForm(
        courts: _courts,
        apiService: _apiService,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt lịch định kỳ thành công!')));
          Provider.of<UserProvider>(context, listen: false).loadUser();
          _loadData();
        },
        onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $msg'))),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final user = Provider.of<UserProvider>(context).member;
    final isVip = (user?.tier ?? 0) >= 2;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildColorLegend(Colors.white, 'Trống'),
                  const SizedBox(width: 12),
                  _buildColorLegend(Colors.blue, 'Của tôi'),
                  const SizedBox(width: 12),
                  _buildColorLegend(Colors.red, 'Đã đặt'),
                ],
              ),
            ),
            Expanded(
              child: SfCalendar(
                view: _calendarView,
                dataSource: BookingDataSource(_bookings, user?.id),
                onTap: _onCalendarTap,
                timeSlotViewSettings: const TimeSlotViewSettings(
                  startHour: 6,
                  endHour: 22,
                  timeIntervalHeight: 60,
                  timeRulerSize: 50,
                ),
                monthViewSettings: const MonthViewSettings(
                  showAgenda: true,
                  appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                ),
                selectionDecoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.blue, width: 2),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton(
            icon: Icon(_calendarView == CalendarView.week ? Icons.calendar_month : Icons.view_week),
            tooltip: _calendarView == CalendarView.week ? 'Xem tháng' : 'Xem tuần',
            onPressed: () => setState(() {
              _calendarView = _calendarView == CalendarView.week ? CalendarView.month : CalendarView.week;
            }),
          ),
        ),
        if (isVip)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'booking_recurring_fab',
              onPressed: _showRecurringBookingSheet,
              icon: const Icon(Icons.repeat),
              label: const Text('Đặt lịch định kỳ'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch đặt sân'),
        actions: [
          IconButton(
            icon: Icon(_calendarView == CalendarView.week ? Icons.calendar_month : Icons.view_week),
            tooltip: _calendarView == CalendarView.week ? 'Xem tháng' : 'Xem tuần',
            onPressed: () => setState(() {
              _calendarView = _calendarView == CalendarView.week ? CalendarView.month : CalendarView.week;
            }),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: (Provider.of<UserProvider>(context).member?.tier ?? 0) >= 2
          ? FloatingActionButton.extended(
              heroTag: 'booking_recurring_fab',
              onPressed: _showRecurringBookingSheet,
              icon: const Icon(Icons.repeat),
              label: const Text('Đặt lịch định kỳ'),
            )
          : null,
    );
  }
}

class _RecurringBookingForm extends StatefulWidget {
  final List<Court> courts;
  final ApiService apiService;
  final VoidCallback onSuccess;
  final void Function(String) onError;

  const _RecurringBookingForm({
    required this.courts,
    required this.apiService,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_RecurringBookingForm> createState() => _RecurringBookingFormState();
}

class _RecurringBookingFormState extends State<_RecurringBookingForm> {
  Court? _court;
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final Set<int> _selectedDays = {1, 3}; // T2, T4 mặc định
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 30));
    _startTime = const TimeOfDay(hour: 8, minute: 0);
    _endTime = const TimeOfDay(hour: 9, minute: 0);
    if (widget.courts.isNotEmpty) _court = widget.courts.first;
  }

  Future<void> _submit() async {
    if (_court == null) {
      widget.onError('Chọn sân');
      return;
    }
    if (_selectedDays.isEmpty) {
      widget.onError('Chọn ít nhất một ngày trong tuần');
      return;
    }
    setState(() => _submitting = true);
    try {
      final st = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
      final et = DateTime(_startDate.year, _startDate.month, _startDate.day, _endTime.hour, _endTime.minute);
      await widget.apiService.createRecurringBooking(
        courtId: _court!.id,
        startDate: _startDate,
        endDate: _endDate,
        startTime: st,
        endTime: et,
        daysOfWeek: _selectedDays.toList()..sort(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.response?.data?.toString() ?? e.message ?? '$e';
      if (mounted) widget.onError(msg);
    } catch (e) {
      if (mounted) widget.onError('$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đặt lịch định kỳ (VIP)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<Court>(
            value: _court,
            decoration: const InputDecoration(labelText: 'Chọn sân'),
            items: widget.courts.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
            onChanged: (val) => setState(() => _court = val),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text('Từ ngày: ${DateFormat('dd/MM/yyyy').format(_startDate)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setState(() => _startDate = d);
            },
          ),
          ListTile(
            title: Text('Đến ngày: ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setState(() => _endDate = d);
            },
          ),
          ListTile(
            title: Text('Giờ bắt đầu: ${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _startTime);
              if (t != null) setState(() => _startTime = t);
            },
          ),
          ListTile(
            title: Text('Giờ kết thúc: ${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _endTime);
              if (t != null) setState(() => _endTime = t);
            },
          ),
          const SizedBox(height: 8),
          const Text('Chọn các ngày trong tuần:', style: TextStyle(fontWeight: FontWeight.w600)),
          Wrap(
            spacing: 8,
            children: [
              ['CN', 0], ['T2', 1], ['T3', 2], ['T4', 3], ['T5', 4], ['T6', 5], ['T7', 6],
            ].map((e) {
              final label = e[0] as String;
              final day = e[1] as int;
              return FilterChip(
                label: Text(label),
                selected: _selectedDays.contains(day),
                onSelected: (v) => setState(() {
                  if (v) _selectedDays.add(day); else _selectedDays.remove(day);
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Xác nhận đặt lịch định kỳ'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class BookingDataSource extends CalendarDataSource {
  final int? currentMemberId;

  BookingDataSource(List<Booking> source, this.currentMemberId) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as Booking).startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments![index] as Booking).endTime;
  }

  @override
  String getSubject(int index) {
    final booking = appointments![index] as Booking;
    return '${booking.court?.name ?? ""} – ${booking.member?.fullName ?? ""}';
  }

  @override
  Color getColor(int index) {
    final booking = appointments![index] as Booking;
    if (booking.memberId == currentMemberId) return Colors.blue;
    return Colors.red;
  }

  @override
  bool isAllDay(int index) => false;
}
