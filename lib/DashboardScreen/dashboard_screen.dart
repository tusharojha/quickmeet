import 'package:duration_picker_dialog_box/duration_picker_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:quickmeet/DashboardScreen/custom_button.dart';
import 'package:quickmeet/clients/calendar_client.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';

enum WhenOptions { Today, Tomorrow, Custom }

List<String> months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  TextEditingController _controller = TextEditingController();
  WhenOptions when = WhenOptions.Tomorrow;

  bool loading = false;
  String eventID = '';
  String meetingLink = 'https://meet.google.com/---';
  Duration duration = Duration(minutes: 25); // in minutes
  bool isCustom = false;
  DateTime date = DateTime.now().add(Duration(days: 1));
  TimeOfDay time = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);

  Future<Map<String, String>> insert({
    required String title,
    required String description,
    required bool shouldNotifyAttendees,
    required bool hasConferenceSupport,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    Map<String, String> eventData = {};

    // If the account has multiple calendars, then select the "primary" one
    String calendarId = "primary";
    cal.Event event = cal.Event();

    event.summary = title;
    event.description = description;

    if (hasConferenceSupport) {
      cal.ConferenceData conferenceData = cal.ConferenceData();
      cal.CreateConferenceRequest conferenceRequest =
          cal.CreateConferenceRequest();
      conferenceRequest.requestId =
          "${startTime.millisecondsSinceEpoch}-${endTime.millisecondsSinceEpoch}";
      conferenceData.createRequest = conferenceRequest;

      event.conferenceData = conferenceData;
    }

    cal.EventDateTime start = new cal.EventDateTime();
    var timezone = '${startTime.timeZoneOffset.toString().split('.')[0]}';
    if (timezone[0] != '-') {
      timezone = '+' + timezone;
    }
    start.dateTime = startTime;
    start.timeZone = "GMT$timezone";
    event.start = start;

    cal.EventDateTime end = new cal.EventDateTime();
    end.timeZone = "GMT$timezone";
    end.dateTime = endTime;
    event.end = end;

    try {
      await CalendarClient.calendar.events
          .insert(event, calendarId,
              conferenceDataVersion: hasConferenceSupport ? 1 : 0,
              sendUpdates: shouldNotifyAttendees ? "all" : "none")
          .then((value) {
        print("Event Status: ${value.status}");
        if (value.status == "confirmed") {
          String joiningLink = '';
          String eventId = '';

          eventId = value.id;

          if (hasConferenceSupport) {
            joiningLink =
                "https://meet.google.com/${value.conferenceData.conferenceId}";

            setState(() {
              meetingLink = joiningLink;
              eventID = value.id;
            });
          }

          eventData = {'id': eventId, 'link': joiningLink};

          print('Event added to Google Calendar');
        } else {
          print("Unable to add event to Google Calendar");
        }
      });
    } catch (e) {
      print('Error creating event $e');
    }

    return eventData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text('QuickMeet'),
        backgroundColor: Colors.teal,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.info),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Schedule a Meeting',
                    style: TextStyle(
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'When?',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  CustomButton(
                    onPressed: () {
                      setState(() {
                        when = WhenOptions.Today;
                        date = DateTime.now();
                        isCustom = false;
                      });
                    },
                    text: 'Today',
                    selected: when == WhenOptions.Today,
                  ),
                  CustomButton(
                    onPressed: () {
                      setState(() {
                        when = WhenOptions.Tomorrow;
                        date = DateTime.now().add(Duration(days: 1));
                        isCustom = false;
                      });
                    },
                    text: 'Tomorrow',
                    selected: when == WhenOptions.Tomorrow,
                  ),
                  CustomButton(
                    onPressed: () {
                      setState(() {
                        when = WhenOptions.Custom;
                      });
                      showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              initialDate: date,
                              helpText: "When's the meeting?",
                              lastDate: DateTime.now().add(Duration(days: 365)))
                          .then((value) {
                        if (value != null) {
                          setState(() {
                            date = value;
                            isCustom = true;
                          });
                        } else {
                          setState(() {
                            date = DateTime.now().add(Duration(days: 1));
                            when = WhenOptions.Tomorrow;
                            isCustom = false;
                          });
                        }
                      });
                    },
                    text: isCustom
                        ? '${date.day}${date.day == 1 ? 'st' : date.day == 2 ? 'nd' : date.day == 3 ? 'rd' : 'th'} ${months[date.month - 1]}'
                        : 'Custom',
                    selected: when == WhenOptions.Custom,
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  CustomButton(
                    text: time.format(context),
                    selected: true,
                    onPressed: () {
                      showTimePicker(
                              context: context,
                              initialTime: time,
                              helpText: "When's the meeting?")
                          .then((value) {
                        if (value != null) {
                          setState(() {
                            time = value;
                          });
                        }
                      });
                    },
                  ),
                  CustomButton(
                    disabled: true,
                    text: date.timeZoneName,
                    selected: false,
                    onPressed: () {},
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "How long the meeting will be?",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              Container(
                child: CustomButton(
                  width: MediaQuery.of(context).size.width - 40,
                  onPressed: () async {
                    var selectedDuration = await showDurationPicker(
                      context: context,
                      initialDuration: duration,
                      durationPickerMode: DurationPickerMode.Minute,
                      showHead: false,
                    );
                    if (selectedDuration != null) {
                      setState(() {
                        duration = selectedDuration;
                      });
                    }
                  },
                  text: '${duration.inMinutes} minutes',
                  selected: true,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "What's the meeting about?",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                width: MediaQuery.of(context).size.width - 40,
                child: TextField(
                  controller: _controller,
                  cursorColor: Colors.teal,
                  decoration: InputDecoration(
                    hintText: "Let's have a meeting about...",
                    focusColor: Colors.teal,
                    hoverColor: Colors.teal,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal, width: 2.0),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal, width: 2.0),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "Meeting Link: ",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              Row(
                children: [
                  CustomButton(
                    width: MediaQuery.of(context).size.width - 40,
                    disabled: true,
                    text: 'https://meet.google.com/ loading...',
                    selected: false,
                    onPressed: () {},
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.info),
                  SizedBox(width: 10),
                  Container(
                    width: MediaQuery.of(context).size.width - 100,
                    child: Text(
                        'By sharing the meeting link, an event will be created on your google calendar too.'),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5.0,
                      spreadRadius: 0.5,
                      offset: Offset(
                        0.5,
                        3.0,
                      ),
                    ),
                  ],
                ),
                child: CustomButton(
                  disabled: loading,
                  width: MediaQuery.of(context).size.width - 40,
                  text: loading ? 'Loading...' : 'Share',
                  selected: !loading,
                  onPressed: () async {
                    setState(() {
                      loading = true;
                    });
                    await HapticFeedback.mediumImpact();
                    var title = _controller.text.isNotEmpty
                        ? _controller.text
                        : 'Quick Meeting';
                    var startTime = DateTime(date.year, date.month, date.day,
                        time.hour, time.minute);
                    var eventDetails = await insert(
                      title: title,
                      description:
                          'Please join the meeting on time.\n\nCreated using Quick Meet App.',
                      shouldNotifyAttendees: true,
                      hasConferenceSupport: true,
                      startTime: startTime,
                      endTime: startTime.add(duration),
                    );
                    setState(() {
                      loading = false;
                    });
                    if (eventDetails.isNotEmpty) {
                      Fluttertoast.showToast(msg: 'Event added successfully!');
                      Share.shareFiles([
                        'https://www.google.com/calendar/ical/$eventID/public/basic.ics'
                      ]);
                    } else {
                      Fluttertoast.showToast(
                          msg: 'Sorry, unable to setup meeting!');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
