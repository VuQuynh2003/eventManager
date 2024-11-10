import 'package:event_manager/event/event_model.dart';
import 'package:event_manager/event/event_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class EventDetailView extends StatefulWidget {
  final EventModel event;
  const EventDetailView({super.key, required this.event});

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  final subjectController = TextEditingController();
  final noteController = TextEditingController();
  final eventService = EventService();

  @override
  void initState() {
    super.initState();
    subjectController.text = widget.event.subject;
    noteController.text = widget.event.note ?? '';
  }

  Future<void> _pickDateTime({required bool isStartTime}) async {
    final initialDate =
        isStartTime ? widget.event.startTime : widget.event.endTime;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      if (!mounted) return;
      // Hiển thị time picker
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (selectedTime != null) {
        final newDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        setState(() {
          if (isStartTime) {
            widget.event.startTime = newDateTime;
            // Tự thiết lập end time sau một tiếng
            if (widget.event.endTime.isAfter(widget.event.startTime)) {
              widget.event.endTime = widget.event.startTime.add(const Duration(
                hours: 1,
              ));
            }
          } else {
            widget.event.endTime = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    widget.event.subject = subjectController.text;
    widget.event.note = noteController.text;
    await eventService.saveEvent(widget.event);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteEvent() async {
    await eventService.deleteEvent(widget.event);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final al = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.id == null ? al!.addEvent : al!.eventDetails),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Tên Sự Kiệns',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Sự kiện cả ngày'),
              trailing: Switch(
                value: widget.event.isAllDay,
                onChanged: (value) {
                  setState(() {
                    widget.event.isAllDay = value;
                  });
                },
              ),
            ),
            if (!widget.event.isAllDay) ...[
              const SizedBox(height: 16),
              ListTile(
                title: Text('Bắt đầu: ${widget.event.formatedStartTimeString}'),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => _pickDateTime(isStartTime: true),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Kết thúc: ${widget.event.formatedEndTimeString}'),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => _pickDateTime(isStartTime: false),
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (widget.event.id != null)
                  FilledButton.tonalIcon(
                      onPressed: _deleteEvent, label: const Text('Xóa')),
                FilledButton.tonalIcon(
                    onPressed: _saveEvent, label: const Text('Lưu sự kiện')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
