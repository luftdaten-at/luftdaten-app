import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:luftdaten.at/controller/trip_controller.dart';
import 'package:luftdaten.at/main.dart';
import 'package:luftdaten.at/page/annotated_picture_page.i18n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../model/measured_data.dart';
import '../model/trip.dart';

class AnnotatedPicturePage extends StatefulWidget {
  const AnnotatedPicturePage({super.key});

  static const String route = 'annotated-picture';

  @override
  State<StatefulWidget> createState() => _AnnotatedPicturePageState();
}

class _AnnotatedPicturePageState extends State<AnnotatedPicturePage> with WidgetsBindingObserver {
  CameraController? cameraController;
  double? minZoom, maxZoom;
  double currentZoom = 1.0, zoomStartedFrom = 1.0;
  _Status status = _Status.loading;
  bool showBoxShadow = false;
  ScreenshotController screenshotController = ScreenshotController();
  late Directory cache;

  @override
  void initState() {
    initCamera();
    getApplicationCacheDirectory().then((dir) => cache = dir);
    super.initState();
  }

  Future<void> initCamera() async {
    List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() {
        status = _Status.failed;
        return;
      });
    }
    cameraController = CameraController(
      cameras.firstWhere((e) => e.lensDirection == CameraLensDirection.back),
      ResolutionPreset.max,
      enableAudio: false,
    );
    await cameraController!.initialize();
    await cameraController!.setFocusMode(FocusMode.auto);
    minZoom = await cameraController!.getMinZoomLevel();
    maxZoom = await cameraController!.getMaxZoomLevel();
    if (!mounted) return;
    setState(() {
      status = _Status.capture;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Luftqualität dokumentieren'.i18n, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
      ),
      body: buildContent(context),
    );
  }

  Widget buildContent(BuildContext context) {
    switch (status) {
      case _Status.loading:
        return buildLoading(context);
      case _Status.failed:
        return buildFailed(context);
      case _Status.capture:
        return buildCamera(context);
      case _Status.view:
        return buildView(context);
      case _Status.processing:
        return buildProcessing(context);
    }
  }

  Widget buildLoading(BuildContext context) {
    return Center(child: Text('Kamera wird geladen...'.i18n));
  }

  Widget buildFailed(BuildContext context) {
    return Center(child: Text('Kamera konnte nicht geöffnet werden'.i18n));
  }

  Widget buildCamera(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      double width = box.maxWidth;
      double height = box.maxHeight;
      bool landscape = width > height;
      double shortSideScreen = min(width, height);
      double imShortSide = .8 * shortSideScreen;
      double imLongSide = 4 / 3 * imShortSide;
      double imWidth = landscape ? imLongSide : imShortSide;
      double imHeight = landscape ? imShortSide : imLongSide;
      double scaleFactor = imWidth / 500;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: buildBetaBanner(),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: (details) {
              currentZoom = zoomStartedFrom;
            },
            onScaleUpdate: (details) {
              currentZoom = zoomStartedFrom * details.scale;
              if (currentZoom < 1) {
                currentZoom = 1; // Unfortunately, can't zoom out (for wide angle)
              }
              if (currentZoom > maxZoom!) currentZoom = maxZoom!;
              cameraController!.setZoomLevel(currentZoom);
            },
            onScaleEnd: (details) {
              zoomStartedFrom = currentZoom;
            },
            child: Screenshot(
              controller: screenshotController,
              child: SizedBox(
                width: imWidth,
                height: imHeight,
                child: Stack(
                  children: [
                    ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.center,
                        maxHeight: imWidth * cameraController!.value.aspectRatio,
                        child: SizedBox(
                          width: imWidth,
                          height: imWidth * cameraController!.value.aspectRatio,
                          child: CameraPreview(cameraController!),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      // TODO add support for multi-device use
                      child: Consumer<TripController>(
                        builder: (context, tripController, _) {
                          Trip? trip = tripController.ongoingTrips.values.firstOrNull;
                          if (trip?.data.lastOrNull != null) {
                            List<FormattedValue> maps = FormattedValue.fromDataPoint(trip!.data.last);
                            return Container(
                              width: 176 * scaleFactor,
                              decoration: BoxDecoration(
                                color: showBoxShadow ? Colors.white.withAlpha(150) : null,
                              ),
                              padding: EdgeInsets.all(8 * scaleFactor),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  for (var kv in maps)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "${kv.entry}:",
                                          style: TextStyle(
                                            fontSize: 24 * scaleFactor,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Colors.black.withOpacity(showBoxShadow ? 1 : 0.5),
                                          ),
                                        ),
                                        Text(
                                          kv.value,
                                          style: TextStyle(
                                            fontSize: 24 * scaleFactor,
                                            fontWeight: FontWeight.bold,
                                            color: kv.color.withOpacity(showBoxShadow ? 1 : 0.5),
                                          ),
                                        )
                                      ],
                                    )
                                ],
                              ),
                            );
                          } else {
                            return const SizedBox();
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(imWidth / 15),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: SvgPicture.asset(
                          'assets/LD_logo_wordmark_blue.svg',
                          width: imWidth / 2,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                        value: showBoxShadow,
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            showBoxShadow = val;
                          });
                        }),
                    Text('Messdaten-Box schattieren'.i18n),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await captureImage(context, imWidth, imHeight, scaleFactor);
                    setState(() {
                      status = _Status.view;
                    });
                  },
                  icon: const Icon(Icons.camera),
                  label: Text('Foto aufnehmen'.i18n),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget buildView(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      double width = box.maxWidth;
      double height = box.maxHeight;
      bool landscape = width > height;
      double shortSideScreen = min(width, height);
      double imShortSide = .8 * shortSideScreen;
      double imLongSide = 4 / 3 * imShortSide;
      double imWidth = landscape ? imLongSide : imShortSide;
      double imHeight = landscape ? imShortSide : imLongSide;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: buildBetaBanner(),
            ),
            Image.memory(
              Uint8List.fromList(File('${cache.path}/annotated.png').readAsBytesSync()),
              width: imWidth,
              height: imHeight,
            ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 3),
                  Builder(builder: (context) {
                    return FilledButton.icon(
                      onPressed: () async {
                        final box = context.findRenderObject() as RenderBox?;
                        await Share.shareXFiles(
                          [XFile('${cache.path}/annotated.png')],
                          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                        );
                      },
                      icon: Icon(Platform.isIOS ? Icons.ios_share : Icons.share),
                      label: Text('Foto teilen'.i18n),
                    );
                  }),
                  if (Platform.isAndroid)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final params = SaveFileDialogParams(
                          sourceFilePath: '${cache.path}/annotated.png',
                        );
                        await FlutterFileDialog.saveFile(params: params);
                      },
                      icon: const Icon(Icons.save_alt),
                      label: Text('Foto speichern'.i18n),
                    ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
                      primaryColor: ColorScheme.fromSeed(seedColor: Colors.red).primary,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        setState(() {
                          status = _Status.capture;
                        });
                      },
                      icon: const Icon(Icons.close),
                      label: Text('Neues Foto'.i18n),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget buildProcessing(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      double width = box.maxWidth;
      double height = box.maxHeight;
      bool landscape = width > height;
      double shortSideScreen = min(width, height);
      double imShortSide = .8 * shortSideScreen;
      double imLongSide = 4 / 3 * imShortSide;
      double imHeight = landscape ? imShortSide : imLongSide;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: buildBetaBanner(),
            ),
            SizedBox(
              height: imHeight,
              child: Center(
                child: SpinKitDualRing(
                  color: Theme.of(context).colorScheme.surfaceTint,
                ),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      );
    });
  }

  Widget buildBetaBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceTint,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Beta-Version'.i18n,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        'Die Kamera-Funktion ist noch in Entwicklung.'.i18n,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> captureImage(
      BuildContext context, double imWidth, double imHeight, double scaleFactor) async {
    setState(() {
      status = _Status.processing;
    });
    XFile image = await cameraController!.takePicture();
    double extraFontScaling = 1.1;
    if (!context.mounted) return;
    Color primary = Theme.of(context).primaryColor;
    Uint8List data = await ScreenshotController().captureFromWidget(
      Material(
        textStyle: Theme.of(context).textTheme.bodyMedium,
        child: Builder(builder: (context) {
          return SizedBox(
            width: imWidth,
            height: imHeight,
            child: Stack(
              children: [
                ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.center,
                    maxHeight: imWidth * cameraController!.value.aspectRatio,
                    child: SizedBox(
                      width: imWidth,
                      height: imWidth * cameraController!.value.aspectRatio,
                      child: Image.memory(
                        Uint8List.fromList(File(image.path).readAsBytesSync()),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Builder(
                    builder: (context) {
                      MeasuredDataPoint? value = getIt<TripController>().ongoingTrips.values.firstOrNull?.data.lastOrNull;
                      if (value != null) {
                        List<FormattedValue> maps = FormattedValue.fromDataPoint(value);
                        return Container(
                          width: 176 * scaleFactor,
                          decoration: BoxDecoration(
                            color: showBoxShadow ? Colors.white.withAlpha(150) : null,
                          ),
                          padding: EdgeInsets.all(8 * scaleFactor),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (var kv in maps)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${kv.entry}:",
                                      style: TextStyle(
                                        fontSize: 24 * scaleFactor * extraFontScaling,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black.withOpacity(showBoxShadow ? 1 : 0.5),
                                      ),
                                    ),
                                    Text(
                                      kv.value,
                                      style: TextStyle(
                                        fontSize: 24 * scaleFactor * extraFontScaling,
                                        fontWeight: FontWeight.bold,
                                        color: kv.color.withOpacity(showBoxShadow ? 1 : 0.5),
                                      ),
                                    )
                                  ],
                                )
                            ],
                          ),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(imWidth / 15),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: SvgPicture.asset(
                      'assets/LD_logo_wordmark_blue.svg',
                      width: imWidth / 2,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
    File('${cache.path}/annotated.png').writeAsBytesSync(data);
    File('${cache.path}/annotatedMeta.json').writeAsStringSync(json.encode({
      'time': DateTime.now().toIso8601String(),
      if (getIt<TripController>().ongoingTrips.values.first.data.last.location != null)
        'lat': getIt<TripController>().ongoingTrips.values.first.data.last.location!.latitude,
      if (getIt<TripController>().ongoingTrips.values.first.data.last.location != null)
        'long': getIt<TripController>().ongoingTrips.values.first.data.last.location!.longitude,
    }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      cameraController?.initialize().then((_) => setState(() => status = _Status.capture));
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}

enum _Status { loading, failed, capture, view, processing }
