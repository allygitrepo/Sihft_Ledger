import 'package:flutter/material.dart';
import 'responsive_breakpoints.dart';

class AppSpacing {
  static double getHorizontalPadding(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceTypeFromContext(context);
    switch (deviceType) {
      case DeviceScreenType.mobile:
        return 16.0;
      case DeviceScreenType.tablet:
        return 32.0;
      case DeviceScreenType.desktop:
        return 64.0;
    }
  }

  static double getVerticalPadding(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceTypeFromContext(context);
    switch (deviceType) {
      case DeviceScreenType.mobile:
        return 16.0;
      case DeviceScreenType.tablet:
        return 24.0;
      case DeviceScreenType.desktop:
        return 32.0;
    }
  }

  static double getCardPadding(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceTypeFromContext(context);
    switch (deviceType) {
      case DeviceScreenType.mobile:
        return 12.0;
      case DeviceScreenType.tablet:
        return 16.0;
      case DeviceScreenType.desktop:
        return 20.0;
    }
  }

  static int getGridCrossAxisCount(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceTypeFromContext(context);
    switch (deviceType) {
      case DeviceScreenType.mobile:
        return 1;
      case DeviceScreenType.tablet:
        return 2;
      case DeviceScreenType.desktop:
        return 4;
    }
  }

  static double getMaxFormWidth(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceTypeFromContext(context);
    switch (deviceType) {
      case DeviceScreenType.mobile:
        return double.infinity;
      case DeviceScreenType.tablet:
        return 500.0;
      case DeviceScreenType.desktop:
        return 600.0;
    }
  }
}
