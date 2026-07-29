import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:moment_dart/moment_dart.dart';

class DateRangeWidget extends StatefulWidget {

  bool onInitRender;
  CalendarDatePicker2Type? calendarTYpe;
  Function(List<DateTime?>) onChanged;
  List<DateTime?> dates = [
  ];
  DateRangeWidget({super.key,this.onInitRender = true, this.calendarTYpe = CalendarDatePicker2Type.range,  required this.dates, required this.onChanged});

  @override
  State<DateRangeWidget> createState() => _DateRangeWidgetState();
}

class _DateRangeWidgetState extends State<DateRangeWidget> {
  TextEditingController date = TextEditingController();

  _showDateRanges() async {
    var res = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
          calendarType: widget.calendarTYpe,
          firstDate: DateTime(1999),
          lastDate: DateTime(3000)),
      dialogSize: const Size(350, 400),
      value: widget.dates,
      borderRadius: BorderRadius.circular(15),
    );

    if (res != null) {
      widget.dates = res;
      widget.onChanged(widget.dates);
      _renderDates();
    }
  }

  _renderDates() {
    date.value = TextEditingValue(
        text:
            '${widget.dates.first?.format(payload: 'DD/MM/YYYY')} - ${widget.dates.last?.format(payload: 'DD/MM/YYYY')}');
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _renderDates();
      if(widget.onInitRender){
         widget.onChanged(widget.dates);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: date,
      readOnly: true,
      decoration: InputDecoration(
          hintText: 'DD/MM/YYYY',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderSide: BorderSide(style: BorderStyle.none, width: 0)),
          suffixIcon: IconButton(
              onPressed: _showDateRanges, icon: Icon(Icons.calendar_month))),
    );
  }
}
