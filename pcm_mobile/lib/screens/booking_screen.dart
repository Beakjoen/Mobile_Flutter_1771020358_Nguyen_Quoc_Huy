import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/booking.dart';
import '../models/court.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiService _apiService = ApiService();
  List<Booking> _bookings = [];
  List<Court> _courts = [];
  bool _isLoading = true;
  final CalendarController _calendarController = CalendarController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      // Fetch 1 month range
      final from = now.subtract(const Duration(days: 7));
      final to = now.add(const Duration(days: 30));

      final courtsRes = await _apiService.getCourts();
      final bookingsRes = await _apiService.getCalendar(from, to);

      setState(() {
        _courts = (courtsRes.data as List).map((e) => Court.fromJson(e)).toList();
        _bookings = (bookingsRes.data as List).map((e) => Booking.fromJson(e)).toList();
        _isLoading = false;
      });
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt sân thành công!')));
      
      // Reload user balance and calendar
      Provider.of<UserProvider>(context, listen: false).loadUser();
      _loadData();
    } catch (e) {
      // Dio error handling usually gives e.response.data
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _onCalendarTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.calendarCell) {
      final DateTime date = details.date!;
      // Default 1 hour slot
      final DateTime start = date;
      final DateTime end = date.add(const Duration(hours: 1));

      _showBookingDialog(start, end);
    } else if (details.targetElement == CalendarElement.appointment) {
      final Booking booking = details.appointments!.first;
      _showBookingDetails(booking);
    }
  }

  void _showBookingDialog(DateTime start, DateTime end) {
    Court? selectedCourt = _courts.isNotEmpty ? _courts.first : null;
    double price = selectedCourt != null ? selectedCourt.pricePerHour : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 16
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
                    onChanged: (val) {
                      setModalState(() {
                        selectedCourt = val;
                        price = val!.pricePerHour;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Thời gian: ${start.toString().split('.')[0]} - ${end.toString().split('.')[0]}'),
                  const SizedBox(height: 8),
                  Text('Giá dự kiến: ${price.toStringAsFixed(0)} đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedCourt != null) {
                          _createBooking(selectedCourt!.id, start, end);
                        }
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết đặt sân #${booking.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sân: ${booking.court?.name ?? "Unknown"}'),
            Text('Người đặt: ${booking.member?.fullName ?? "Unknown"}'),
            Text('Thời gian: ${booking.startTime.toString().split('.')[0]}'),
            Text('Trạng thái: ${booking.status == 1 ? "Đã xác nhận" : "Chờ/Hủy"}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).member;

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch đặt sân')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SfCalendar(
              view: CalendarView.week,
              controller: _calendarController,
              dataSource: BookingDataSource(_bookings, user?.id),
              onTap: _onCalendarTap,
              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 6,
                endHour: 22,
                timeIntervalHeight: 60,
              ),
              selectionDecoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.blue, width: 2),
              ),
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
    return '${booking.court?.name} - ${booking.member?.fullName}';
  }

  @override
  Color getColor(int index) {
    final booking = appointments![index] as Booking;
    if (booking.memberId == currentMemberId) {
      return Colors.blue; // My booking
    }
    return Colors.red; // Others booking
  }

  @override
  bool isAllDay(int index) {
    return false;
  }
}
