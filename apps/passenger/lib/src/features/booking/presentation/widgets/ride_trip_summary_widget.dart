import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger/src/app/theme/app_theme.dart';

class const RideTripSummaryWidget({
  super.key,
  required this.pickupLabel,
  required this.destinationName,
  required this.destinationAddress,
}) extends StatelessWidget {
  final String pickupLabel;
  final String destinationName;
  final String destinationAddress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Details',
            style: TextStyle(
              color: context.colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          _TripLocationTimeline(
            children: [
              const _LocationIcon(icon: LucideIcons.locate_fixed),
              _LocationDetails(label: 'Pickup', value: pickupLabel),
              const _DashedRouteConnector(),
              const _LocationIcon(icon: LucideIcons.map_pin),
              _LocationDetails(
                label: 'Destination',
                value: destinationName,
                subtitle: destinationAddress,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class const _TripLocationTimeline({required super.children})
    extends MultiChildRenderObjectWidget {
  static const _routeGap = 38.0;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TripLocationTimelineRenderObject(routeGap: _routeGap);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _TripLocationTimelineRenderObject renderObject,
  ) {}
}

class _TripLocationParentData() extends ContainerBoxParentData<RenderBox> {}

class _TripLocationTimelineRenderObject({required this.routeGap})
    extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TripLocationParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TripLocationParentData> {
  static const _iconSize = 18.0;
  static const _contentGap = 12.0;
  static const _connectorWidth = 2.0;

  final double routeGap;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _TripLocationParentData) {
      child.parentData = _TripLocationParentData();
    }
  }

  RenderBox get _pickupIcon => firstChild!;

  RenderBox get _pickupDetails => childAfter(_pickupIcon)!;

  RenderBox get _connector => childAfter(_pickupDetails)!;

  RenderBox get _destinationIcon => childAfter(_connector)!;

  RenderBox get _destinationDetails => childAfter(_destinationIcon)!;

  @override
  void performLayout() {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : constraints.minWidth;
    final detailsWidth = width > _iconSize + _contentGap
        ? width - _iconSize - _contentGap
        : 0.0;
    final detailsConstraints = BoxConstraints.tightFor(width: detailsWidth);

    _pickupIcon.layout(
      const BoxConstraints.tightFor(width: _iconSize, height: _iconSize),
      parentUsesSize: true,
    );
    _pickupDetails.layout(detailsConstraints, parentUsesSize: true);
    _destinationIcon.layout(
      const BoxConstraints.tightFor(width: _iconSize, height: _iconSize),
      parentUsesSize: true,
    );
    _destinationDetails.layout(detailsConstraints, parentUsesSize: true);

    final destinationY = _pickupDetails.size.height + routeGap;
    final connectorHeight = (destinationY - _iconSize)
        .clamp(0.0, double.infinity)
        .toDouble();
    _connector.layout(
      BoxConstraints.tightFor(width: _connectorWidth, height: connectorHeight),
      parentUsesSize: true,
    );

    final totalHeight = destinationY + _destinationDetails.size.height;
    size = constraints.constrain(Size(width, totalHeight));

    _setOffset(_pickupIcon, Offset.zero);
    _setOffset(_pickupDetails, const Offset(_iconSize + _contentGap, 0));
    _setOffset(
      _connector,
      const Offset((_iconSize - _connectorWidth) / 2, _iconSize),
    );
    _setOffset(_destinationIcon, Offset(0, destinationY));
    _setOffset(
      _destinationDetails,
      Offset(_iconSize + _contentGap, destinationY),
    );
  }

  void _setOffset(RenderBox child, Offset offset) {
    (child.parentData! as _TripLocationParentData).offset = offset;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

class const _LocationIcon({required this.icon}) extends StatelessWidget {
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Icon(icon, size: 18, color: context.colorScheme.onSurface),
    );
  }
}

class const _LocationDetails({
  required this.label,
  required this.value,
  this.subtitle,
}) extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle case final address? when address.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

class const _DashedRouteConnector() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: const ValueKey('trip-route-dashes'),
      painter: _DashedRoutePainter(
        context.colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
      ),
    );
  }
}

class const _DashedRoutePainter(this.color) extends CustomPainter {
  static const _dashHeight = 4.0;
  static const _gapHeight = 5.0;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    var top = 0.0;
    while (top < size.height) {
      final bottom = (top + _dashHeight).clamp(0.0, size.height).toDouble();
      if (bottom > top) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, top, size.width, bottom - top),
            Radius.circular(size.width / 2),
          ),
          paint,
        );
      }
      top += _dashHeight + _gapHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoutePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

@Preview(
  group: 'Trip selection',
  name: 'Long destination address',
  size: Size(390, 280),
)
Widget rideTripSummaryLongAddressPreview() {
  return MaterialApp(
    theme: AppTheme.data,
    home: const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: RideTripSummaryWidget(
          pickupLabel: 'Mountain View',
          destinationName: 'Silicon Valley Corporate Catering',
          destinationAddress: '1390 Pear Avenue, Mountain View, California 94043, United States',
        ),
      ),
    ),
  );
}
