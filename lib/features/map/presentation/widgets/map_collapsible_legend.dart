import 'package:flutter/material.dart';
import 'package:luftdaten.at/features/map/presentation/pages/map_page.i18n.dart';
import 'package:luftdaten.at/features/map/presentation/widgets/map_dimension_legend.dart';

/// Full-width collapsible colour legend pinned to the bottom of the Luftkarte.
class MapCollapsibleLegend extends StatefulWidget {
  const MapCollapsibleLegend({
    super.key,
    required this.dimensionId,
    this.onHeightChanged,
  });

  final int dimensionId;

  /// Called when the panel height changes (collapse, expand, or animation tick).
  final ValueChanged<double>? onHeightChanged;

  /// Height of the collapsed panel (strip + label row), excluding expanded content.
  static const double collapsedHeight = 44;

  @override
  State<MapCollapsibleLegend> createState() => _MapCollapsibleLegendState();
}

class _MapCollapsibleLegendState extends State<MapCollapsibleLegend>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 300);
  static const _swipeVelocityThreshold = 300.0;

  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  final GlobalKey _panelKey = GlobalKey();
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animationDuration);
    _expandAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.addListener(_reportHeight);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed || status == AnimationStatus.completed) {
        setState(() {});
        _reportHeight();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportHeight());
  }

  @override
  void didUpdateWidget(MapCollapsibleLegend oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dimensionId != widget.dimensionId && _expanded) {
      _setExpanded(false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reportHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _panelKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        widget.onHeightChanged?.call(box.size.height);
      }
    });
  }

  void _setExpanded(bool expanded) {
    if (_expanded == expanded) return;
    setState(() => _expanded = expanded);
    if (expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _reportHeight();
  }

  void _toggle() => _setExpanded(!_expanded);

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -_swipeVelocityThreshold) {
      _setExpanded(true);
    } else if (velocity > _swipeVelocityThreshold) {
      _setExpanded(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!MapDimensionLegendData.hasLegend(widget.dimensionId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onHeightChanged?.call(0);
      });
      return const SizedBox.shrink();
    }

    final semanticsLabel =
        _expanded ? 'Farblegende ausblenden'.i18n : 'Farblegende einblenden'.i18n;

    return Semantics(
      button: true,
      label: semanticsLabel,
      expanded: _expanded,
      child: Material(
        key: _panelKey,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        color: Theme.of(context).colorScheme.surface,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MapDimensionLegendStrip(
                  dimensionId: widget.dimensionId,
                  expanded: _expanded,
                ),
                if (_expanded || _controller.isAnimating)
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    axisAlignment: -1,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                      ),
                      child: SingleChildScrollView(
                        key: const Key('map-legend-expanded-content'),
                        child: MapDimensionLegendContent(dimensionId: widget.dimensionId),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
