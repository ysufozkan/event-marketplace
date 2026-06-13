import 'package:flutter/material.dart';

class AppColors {
  // Shared across all roles
  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF30D158);
  static const textPrimary = Color(0xFF1A0010);
  static const textSecondary = Color(0xFF6E6377);
  static const surface = Colors.white;

  // Attendee — rose/amber (warm, social, vibrant)
  static const attendeePrimary = Color(0xFFFF2D55);
  static const attendeeSecondary = Color(0xFFFF9500);
  static const attendeeBackground = Color(0xFFFFF5F7);

  // Organizer — forest green (professional, growth)
  static const organizerPrimary = Color(0xFF16A34A);
  static const organizerSecondary = Color(0xFF4ADE80);
  static const organizerBackground = Color(0xFFF0FDF4);

  // Staff/Kapıcı — warm brown (grounded, reliable)
  static const staffPrimary = Color(0xFF795548);
  static const staffSecondary = Color(0xFFA1887F);
  static const staffBackground = Color(0xFFEFEBE9);

  // Backward-compat aliases (= attendee defaults)
  static const primary = attendeePrimary;
  static const secondary = attendeeSecondary;
  static const background = attendeeBackground;
  static const cardShadow = Color(0x14FF2D55);
}
