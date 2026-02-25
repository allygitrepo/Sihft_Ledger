import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;
}

enum DeviceScreenType {
  mobile,
  tablet,
  desktop,
}

DeviceScreenType getDeviceType(BoxConstraints constraints) {
  if (constraints.maxWidth < ResponsiveBreakpoints.mobile) {
    return DeviceScreenType.mobile;
  } else if (constraints.maxWidth < ResponsiveBreakpoints.tablet) {
    return DeviceScreenType.tablet;
  } else {
    return DeviceScreenType.desktop;
  }
}

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobile &&
        width < ResponsiveBreakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;
  }

  static DeviceScreenType getDeviceTypeFromContext(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.mobile) {
      return DeviceScreenType.mobile;
    } else if (width < ResponsiveBreakpoints.tablet) {
      return DeviceScreenType.tablet;
    } else {
      return DeviceScreenType.desktop;
    }
  }
}
