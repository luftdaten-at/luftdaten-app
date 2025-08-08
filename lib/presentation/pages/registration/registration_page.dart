import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:luftdaten.at/controller/http_provider.dart';
import 'package:luftdaten.at/main.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/ble_device.dart';
import '../widget/ui.dart';

/*
class RegistrationData {
  RegistrationData();

  BleDevice? device;
  String? email;
  int? height;
  int? location;
  Point? geolocation;
  String? chipid;

  Map<String, dynamic> toJson() => {
        "mac": device?.bleMacAddress,
        "email": email,
        "height": height?.toString(),
        "location": location?.toString(),
        "latitude": geolocation?.x,
        "longitude": geolocation?.y
      };
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.device});

  static const String route = 'register';
  final BleDevice device;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  RegistrationData regData = RegistrationData();
  String error = "Kontaktiere Server...";

  @override
  void initState() {
    super.initState();
    getIt<LDHttpProvider>().checkStation(widget.device.bleMacAddress).then((response) {
      regData.device = widget.device;
      print("Resp = $response -> ${response.statusCode}");
      if (response.statusCode == 404) {
        regData.chipid = response.body;
      } else if (response.statusCode == 200) {
        List<String> res = response.body.split(";");
        try {
          regData.location = int.parse(res[0]);
          regData.height = int.parse(res[1]);
          regData.geolocation = Point<double>(double.parse(res[2]), double.parse(res[3]));
          regData.chipid = res[4];
        } catch (_, __) {}
      } else {
        error = "Server Problem: ${response.statusCode}. Probiere es später nocheinmal";
        print("Dazed and confused");
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Register3Page(
            data: regData,
            chipid: regData.chipid!,
            regSuccess: false,
          ),
        ),
      );
    }).catchError((_) {
      error = "HTTP Protokoll Fehler. Probiere es später nocheinmal";
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: LDAppBar(context, "Umgebungsdaten"), body: Center(child: Text(error)));
  }
}

class Register1Page extends StatefulWidget {
  const Register1Page({super.key, required this.data});

  final RegistrationData data;

  @override
  State<Register1Page> createState() => _Register1PageState();
}

class _Register1PageState extends State<Register1Page> {
  final MapController _controller = MapController();
  StreamSubscription<Position>? _geoPosStream;
  StreamSubscription<MapEvent>? _mapEvents;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Position? position;
  LatLng? myPos;
  Point<double>? markerPos;

  @override
  void initState() {
    super.initState();
    _geoPosStream = Geolocator.getPositionStream().listen((pos) {
      setState(() {
        position = pos;
        LatLng latLng = LatLng(position!.latitude, position!.longitude);
        _controller.move(latLng, 18.0);
        markerPos = _controller.camera.latLngToScreenPoint(latLng);
        _geoPosStream!.cancel();
      });
    });
    _mapEvents = _controller.mapEventStream.listen((event) {
      markerPos = _controller.camera.latLngToScreenPoint(_controller.camera.center);
    });
  }

  @override
  void dispose() {
    _geoPosStream?.cancel();
    super.dispose();
  }

  late RegistrationData regData = widget.data;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.sizeOf(context).height;
    double width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: LDAppBar(context, "Umgebungsdaten"),
      body: Container(
        color: Colors.grey[200],
        height: height,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "1. Markiere in der Karte den Standort der Sensorstation",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                SizedBox(
                  width: width,
                  height: height / 3,
                  child: FlutterMap(
                    mapController: _controller,
                    options: MapOptions(
                      initialCenter: (position != null)
                          ? LatLng(position!.latitude, position!.longitude)
                          : const LatLng(48.21919466912646, 16.383482313924404),
                      initialZoom: 10.0,
                      maxZoom: 18,
                    ),
                    children: [
                      markerPos != null
                          ? Positioned(
                              left: markerPos!.x - 23.0,
                              top: markerPos!.y - 48.0,
                              child: const Icon(
                                Icons.person_pin_circle,
                                size: 48,
                                color: Colors.red,
                              ),
                            )
                          : Container(),
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.pmble.app',
                      ),
                      IgnorePointer(child: CurrentLocationLayer()),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16, left: 16.0),
                  child: Text(
                    "2. In welcher Lage ist der Sensor?",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 32.0, right: 32.0),
                  child: DropdownButtonFormField<int>(items: const [
                    DropdownMenuItem<int>(value: 1, child: Text("Innenhof")),
                    DropdownMenuItem<int>(value: 2, child: Text("Im Grünen")),
                    DropdownMenuItem<int>(value: 3, child: Text("Innenraum")),
                    DropdownMenuItem<int>(
                      value: 4,
                      child: Text("Straßenseitig (wenig befahren)"),
                    ),
                    DropdownMenuItem<int>(
                      value: 5,
                      child: Text("Straßenseitig (mittel befahren)"),
                    ),
                    DropdownMenuItem<int>(
                      value: 6,
                      child: Text("Straßenseitig (viel befahren)"),
                    ),
                  ], onChanged: (l) => regData.location = l),
                ),
                const Padding(
                    padding: EdgeInsets.only(top: 16, left: 16.0),
                    child: Text(
                      "3. In welcher Höhe am Haus ist der Sensor positioniert? (falls outdoor)",
                      style: TextStyle(fontSize: 20),
                    )),
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16.0, right: 32.0),
                  child: TextFormField(
                    onSaved: (v) => regData.height = int.parse(v!),
                    initialValue: "",
                    decoration: const InputDecoration(labelText: "Höhe in Zentimetern"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: UniqueKey(),
        onPressed: () {
          if ((_formKey.currentState?.validate())!) {
            print("Before Save: $regData");
            regData.geolocation = Point(
              _controller.camera.center.latitude,
              _controller.camera.center.longitude,
            );
            _formKey.currentState!.save();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Register2Page(data: regData),
              ),
            );
          }
        },
        icon: const Icon(Icons.navigate_next_outlined),
        label: const Text("Weiter"),
      ),
    );
  }
}

class Register2Page extends StatefulWidget {
  const Register2Page({super.key, required this.data});

  final RegistrationData data;

  @override
  State<Register2Page> createState() => _Register2PageState();
}

class _Register2PageState extends State<Register2Page> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool checkedConsent = false;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.sizeOf(context).height;
    double width = MediaQuery.sizeOf(context).width;

    print(
        "Got regData: ${widget.data} - ${widget.data.geolocation?.x}, ${widget.data.geolocation?.y}");
    return Scaffold(
      appBar: LDAppBar(context, "E-Mail & Datenschutz"),
      body: Container(
          color: Colors.grey[200],
          height: height,
          child: SingleChildScrollView(
              child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                            child: Text(
                          "E-Mail-Adresse (optional)",
                          style: TextStyle(fontSize: 20),
                        )),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16, left: 16.0, right: 32.0),
                        child: TextFormField(
                          onSaved: (v) => widget.data.email = v!,
                          initialValue: "",
                          decoration: const InputDecoration(labelText: "mail@example.com"),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 16, left: 16.0),
                        child: Text(
                          "Die E-Mail-Adresse wird nur für wichtige Informationen (wie kritische "
                          "Updates) über die Luftdaten Messstation verwendet und wird auf "
                          "keinen Fall an Dritte weitergegeben",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16, left: 32.0, right: 32.0),
                        child: Row(children: [
                          Checkbox(
                            onChanged: (bool? v) {
                              setState(() {
                                checkedConsent = v ?? false;
                              });
                            },
                            value: checkedConsent,
                          ),
                          Flexible(
                              child: RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Hiermit bestätige ich die ',
                                  style: TextStyle(color: Colors.black),
                                ),
                                TextSpan(
                                  text: 'Datenschutzerklärung von luftdaten.at',
                                  style: const TextStyle(color: Colors.blue),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () =>
                                        launchUrl(Uri.parse('https://luftdaten.at/datenschutz/')),
                                ),
                                const TextSpan(
                                  text: ' gelesen und akzeptiert zu haben',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          )),
                        ]),
                      ),
                    ],
                  )))),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: UniqueKey(),
        onPressed: () {
          if (!checkedConsent) {
            //LDAlert(context, const Text("Der Datenschutzerklärung muss zugestimmt werden"), false);
            return;
          }
          if ((_formKey.currentState?.validate())!) {
            _formKey.currentState!.save();
            var jj = jsonEncode(widget.data);
            print("JJ = $jj");
            getIt<LDHttpProvider>()
                .sendDataWithResponse(
                    "https://dev.luftdaten.at/d/station/register", jsonEncode(widget.data))
                .then((response) {
              if (response.statusCode == 200) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => Register3Page(
                            data: widget.data, chipid: response.body, regSuccess: true)));
              } else {
                //LDAlert(
                //    context,
                //    Text(
                //        "Das Registrieren schlug fehl. Bitte informiere info@luftdaten.at mit den folgenden Fehlerdaten: "
                //        "Status-Code: ${response.statusCode}. Timestamp: ${DateTime.now()}",
                //        style: TextStyle(fontSize: 16)),
                //    false);
                print("Error occured: ${response.body}");
              }
            });
          }
        },
        icon: const Icon(Icons.navigate_next_outlined),
        label: const Text("Weiter"),
      ),
    );
  }
}

class Register3Page extends StatefulWidget {
  const Register3Page(
      {super.key, required this.data, required this.chipid, required this.regSuccess});

  final bool regSuccess;
  final RegistrationData data;
  final String chipid;

  @override
  State<Register3Page> createState() => _Register3PageState();
}

class _Register3PageState extends State<Register3Page> {
  TextStyle defaultTextStyle = const TextStyle(color: Colors.black, fontSize: 16);

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.sizeOf(context).height;
    double width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: LDAppBar(context, "sensor.community"),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (widget.regSuccess)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      "Gratuliere! Die Registrierung für Luftdaten.at wurde erfolgreich abgeschlossen",
                      style: TextStyle(
                          fontSize: 24, color: Color(0xff2e88c1), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            Card(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        const WidgetSpan(
                          child: Center(
                            child: Text(
                              "Registrierung auf sensor.community",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const TextSpan(text: "\n\n\n"),
                        TextSpan(
                          text: "Du kannst deine Station "
                              "auch für sensor.community registrieren, damit sie auf der Sensor-Karte (",
                          style: defaultTextStyle,
                        ),
                        TextSpan(
                          text: 'maps.sensor.community',
                          style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontSize: 16),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrl(Uri.parse('https://maps.sensor.community')),
                        ),
                        TextSpan(
                          text: ") sichtbar wird.\n\nGehe dazu auf ",
                          style: defaultTextStyle,
                        ),
                        TextSpan(
                          text: 'devices.sensor.community',
                          style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontSize: 16),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () =>
                                launchUrl(Uri.parse('https://devices.sensor.community/?lang=de')),
                        ),
                        TextSpan(
                          text:
                              ' und registriere dich dort ("Registrieren") und gehe dann auf "Neuen Sensor registrieren". Gib hier im Feld "Sensor ID"\n',
                          style: defaultTextStyle,
                        ),
                        WidgetSpan(
                          child: Center(
                            child: SelectableText(
                              widget.chipid,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                        ),
                        TextSpan(
                          text:
                              '\nein, bei "Sensor Board" wähle "esp32" aus (siehe Beispiel unten) '
                              'und bei "Sensortyp" "SPS30". Klicke dann auf ">>hier<<" bei '
                              'Hardware-Konfiguration und gib im neu erscheinenden Feld bei '
                              '"PIN" 16 ein. Die restlichen Formulardaten sollten '
                              'selbsterklärend sein bzw. können auch leer gelassen werden',
                          style: defaultTextStyle,
                        ),
                      ],
                    ),
                  )),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Beispiel: "),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Sensor-Registrierung",
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Sensor ID",
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsets.only(left: 32.0),
                              child: SizedBox(
                                  width: width / 2,
                                  child:
                                      TextFormField(initialValue: widget.chipid, readOnly: true))),
                        ]),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(""),
                        Text(
                          "Nur der numerische Teil des Sensornamen",
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Sensor Board"),
                        Padding(
                          padding: const EdgeInsets.only(left: 32.0),
                          child: SizedBox(
                            width: width / 2,
                            child: DropdownButtonFormField<int>(
                              onChanged: null,
                              value: 1,
                              items: const [
                                DropdownMenuItem<int>(value: 1, child: Text("esp32")),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: UniqueKey(),
        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        icon: const Icon(Icons.check),
        label: const Text("Fertig"),
      ),
    );
  }
}

class Register4Page extends StatefulWidget {
  const Register4Page({super.key, required this.data});

  final RegistrationData data;

  @override
  State<Register4Page> createState() => _Register4PageState();
}

class _Register4PageState extends State<Register4Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LDAppBar(context, "Registrierung"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
                padding: EdgeInsets.all(48.0),
                child: Text(
                    "Die Station wurde bereits erfolgreich bei luftdaten.at registriert. Folgende Optionen stehen bereit:",
                    style: TextStyle(fontSize: 20))),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: FilledButton.tonalIcon(
                  label: const Text("Lage der Station ändern"),
                  icon: const Icon(Icons.edit_location),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => Register1Page(data: widget.data)))),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: FilledButton.tonalIcon(
                  label: const Text("E-Mail-Adresse ändern"),
                  icon: const Icon(Icons.email),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => Register2Page(data: widget.data)))),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: FilledButton.tonalIcon(
                  label: const Text("Sensor.Community Anleitung ansehen"),
                  icon: const Icon(Icons.sensor_occupied),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => Register3Page(
                              data: widget.data, chipid: widget.data.chipid!, regSuccess: false)))),
            ),
          ],
        ),
      ),
    );
  }
}
*/