import 'package:flutter/material.dart';
import '../utills/responsive_breakpoints.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWrapper({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = getDeviceType(constraints);

        switch (deviceType) {
          case DeviceScreenType.mobile:
            return mobile;
          case DeviceScreenType.tablet:
            return tablet ?? mobile;
          case DeviceScreenType.desktop:
            return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 600,
        ),
        child: child,
      ),
    );
  }
}
