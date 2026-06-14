import 'package:flutter/material.dart';
import 'package:luftdaten.at/core/core.dart';
import 'package:luftdaten.at/features/devices/data/ble_device.dart';
import 'package:luftdaten.at/features/map/logic/station_name_resolver.dart';
import 'package:luftdaten.at/core/widgets/change_notifier_builder.dart';

import 'station_display_name.i18n.dart';

/// Shows a station title from local device config or Datahub, with i18n fallback while loading.
class StationDisplayName extends StatefulWidget {
  const StationDisplayName({
    super.key,
    required this.stationId,
    this.localDevice,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String stationId;
  final BleDevice? localDevice;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<StationDisplayName> createState() => _StationDisplayNameState();
}

class _StationDisplayNameState extends State<StationDisplayName> {
  late final StationNameResolver _resolver;

  @override
  void initState() {
    super.initState();
    _resolver = getIt<StationNameResolver>();
    if (widget.localDevice == null) {
      _resolver.ensureLoaded(widget.stationId);
    }
  }

  @override
  void didUpdateWidget(StationDisplayName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.localDevice == null &&
        oldWidget.stationId != widget.stationId) {
      _resolver.ensureLoaded(widget.stationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.localDevice != null) {
      return Text(
        widget.localDevice!.displayName,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    return ChangeNotifierBuilder(
      notifier: _resolver,
      builder: (context, resolver) {
        return Text(
          resolver.displayLabel(
            stationId: widget.stationId,
            localDevice: null,
            fallback: (id) => 'Station #%s'.i18n.fill([id]),
          ),
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}
