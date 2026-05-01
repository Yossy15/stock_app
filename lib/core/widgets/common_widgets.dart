import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/ui_constants.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;

  const AppAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 0.2,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
        ],
      ),
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: leading,
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AppRefresher extends StatelessWidget {
  final RefreshController controller;
  final VoidCallback onRefresh;
  final VoidCallback? onLoading;
  final bool enablePullUp;
  final Widget child;

  const AppRefresher({
    super.key,
    required this.controller,
    required this.onRefresh,
    this.onLoading,
    this.enablePullUp = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      controller: controller,
      onRefresh: onRefresh,
      onLoading: onLoading,
      enablePullUp: enablePullUp,
      header: const WaterDropMaterialHeader(
        backgroundColor: kPrimary,
        color: Colors.white,
        offset: 0,
      ),
      footer: CustomFooter(
        builder: (context, mode) {
          Widget body;
          if (mode == LoadStatus.idle) {
            body = const Text("ดึงขึ้นเพื่อโหลดต่อ",
                style: TextStyle(color: kTextSub, fontSize: 12));
          } else if (mode == LoadStatus.loading) {
            body = const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
            );
          } else if (mode == LoadStatus.failed) {
            body = const Text("การโหลดล้มเหลว คลิกเพื่อลองใหม่",
                style: TextStyle(color: kBorderError, fontSize: 12));
          } else if (mode == LoadStatus.canLoading) {
            body = const Text("ปล่อยเพื่อโหลดต่อ",
                style: TextStyle(color: kPrimary, fontSize: 12));
          } else {
            body = const Text("ไม่มีข้อมูลเพิ่มเติม",
                style: TextStyle(color: kTextSub, fontSize: 12));
          }
          return Container(height: 60.0, child: Center(child: body));
        },
      ),
      child: child,
    );
  }
}

class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppShimmer({
    this.width = double.infinity,
    required this.height,
    this.borderRadius = kRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kBorder.withOpacity(0.5),
      highlightColor: Colors.white.withOpacity(0.5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    this.message = 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.cloudSlash(PhosphorIconsStyle.bold),
                size: 48,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ตของคุณ\nและลองใหม่อีกครั้ง',
              style: TextStyle(fontSize: 13, color: kTextSub),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: 160,
                height: 48,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('ลองใหม่อีกครั้ง'),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.02, 1.02), duration: 1000.ms),
              ),
            ],
          ],
        ),
      ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0)),
    );
  }
}

