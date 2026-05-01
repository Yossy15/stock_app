import 'package:flutter/material.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────

const kPrimary = Color(0xFF1377FF);
const kPrimaryLight = Color(0xFFE6F1FF);
const kSurface = Color(0xFFF7F8FC);
const kCard = Colors.white;
const kBorder = Color(0xFFA7C4EF);
const kBorderFocus = Color(0xFF1377FF);
const kBorderError = Color(0xFFE53935);
const kText = Color(0xFF2F2F2F);
const kTextSub = Color(0xFF7C7F93);
const kTextHint = Color(0xFFB0B3C6);
const kSuccess = Color(0xFF2E7D32);
const kError = Color(0xFFE53935);

const kFieldHeight = 56.0;
const kRadius = 14.0;
const kCardRadius = 20.0;

// ─── Shared Shadows ────────────────────────────────────────────────────────

final kShadowSmall = [
  BoxShadow(
    color: Colors.black.withOpacity(0.03),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
];

final kShadowMedium = [
  BoxShadow(
    color: kPrimary.withOpacity(0.07),
    blurRadius: 28,
    offset: const Offset(0, 8),
  ),
  BoxShadow(
    color: Colors.black.withOpacity(0.03),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
];

final kShadowLarge = [
  BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 32,
    offset: const Offset(0, -8),
  ),
];
