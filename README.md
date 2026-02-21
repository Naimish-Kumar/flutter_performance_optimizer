# Flutter Performance Optimizer ⚡

[![pub package](https://img.shields.io/pub/v/flutter_performance_optimizer.svg)](https://pub.dev/packages/flutter_performance_optimizer)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A powerful developer tool that automatically detects performance issues in Flutter apps and provides actionable suggestions to fix them.

Identify rebuild problems, memory leaks, heavy widgets, and slow animations — all in real time.

**Build faster, smoother apps with confidence ⚡**

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| ✅ Detect excessive widget rebuilds | Tracks how often each widget rebuilds and warns when thresholds are exceeded |
| ✅ Identify potential memory leaks | Monitors memory trends and tracks undisposed controllers |
| ✅ Find large / expensive widgets | Analyzes widget tree depth and complexity |
| ✅ Monitor FPS and frame time | Real-time FPS tracking with build/raster time breakdown |
| ✅ Detect slow animations and jank | Identifies dropped frames during active animations |
| ✅ Track widget tree depth | Warns when widget trees are too deep |
| ✅ Highlight unnecessary setState | Detects excessive setState call patterns |
| ✅ Performance overlay dashboard | Beautiful floating dashboard with tabs for FPS, Memory, Rebuilds, and Suggestions |
| ✅ Automatic optimization suggestions | Smart engine that generates actionable code-level recommendations |
| ✅ 🤖 AI optimization insights | Pattern-based AI assistant for deep architectural advice |
| ✅ 🗺 Rebuild heatmap visualization | Real-time visual overlay showing rebuild intensity on screen |
| ✅ 📈 Performance history timeline | Interactive charts for FPS and Memory trends over time |
| ✅ 🧪 CI performance testing | Built-in test helpers for automated performance regression checks |
| ✅ ⚡ CPU & GPU profiling | Integrated VM profiling for deep performance inspection |
| ✅ Performance score (0-100) | Holistic health score across 7 key performance dimensions |
| ✅ Debug & release mode support | Enabled in debug mode by default; production use optional |
| ✅ devtools integration | Ready for official Flutter DevTools extension support |
| ✅ Minimal setup required | Wrap your app in one widget and you're done |

---

## 🎯 Why Use This Package?

Performance problems are hard to detect manually.

**Common issues:**
- ❌ Too many widget rebuilds
- ❌ Memory not released (controllers, streams)
- ❌ Heavy widget trees slowing layout
- ❌ Animation jank from expensive builds
- ❌ Poor scrolling performance

**This package helps you:**
- ✔ Find issues instantly
- ✔ Improve app smoothness
- ✔ Reduce crashes
- ✔ Optimize UI efficiently
- ✔ Ship production-quality apps

---

## 📦 Installation

Add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_performance_optimizer: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## 🚀 Quick Start

Wrap your app with the optimizer:

```dart
import 'package:flutter_performance_optimizer/flutter_performance_optimizer.dart';

void main() {
  runApp(
    PerformanceOptimizer(
      enabled: true,
      child: MyApp(),
    ),
  );
}
```

That's it ✅ — The optimizer will start monitoring automatically.

---

## 🖥 Performance Dashboard Overlay

Enable the floating dashboard:

```dart
PerformanceOptimizer(
  showDashboard: true,
  child: MyApp(),
);
```

- 🏆 **Score** — Overall performance score (0-100)
- ⚙️ **Settings** — Quick toggle for tracking features

The dashboard features a **Premium Glassmorphic UI** with:
- ✨ **Backdrop Blur** (Gaussian 10.0) for a sleek modern look
- 🎨 **Indigo & Midnight Palettes** with smooth gradients
- 🤏 **Draggable & Resizable** interaction
- 📱 **Responsive Layout** that adapts to screen size
- 🧊 **Soft Shadows & Translucency** for visual depth

---

## 🔍 Rebuild Detection

Automatically tracks widget rebuild frequency.

```
⚠️ Widget "MyWidget" rebuilt 120 times in 2 seconds.
Suggestion: Use const constructor or memoization.
```

Track specific widgets with `PerformanceInspector`:

```dart
PerformanceInspector(
  name: "HomeScreen",
  child: HomeScreen(),
);
```

---

## 🧠 Memory Leak Detection

Detects:
- 📌 Unreleased controllers
- 📌 Streams not disposed
- 📌 Animation controllers not disposed
- 📌 Consistently increasing memory trends

Track disposable resources:

```dart
// In initState:
MemoryTracker.instance.trackDisposable('MyWidget.controller');

// In dispose:
MemoryTracker.instance.markDisposed('MyWidget.controller');
```

```
⚠️ Possible memory leak detected in HomePage.
Controller not disposed.
```

---

## 📏 Large Widget Detection

Find widgets with heavy layouts or deep trees:

```
⚠️ Widget tree depth exceeds 30 levels.
Suggestion: Split into smaller widgets.
```

---

## 🎞 Slow Animation Detection

Detects dropped frames and animation jank:

```dart
// Register active animations:
AnimationTracker.instance.registerAnimation('fadeIn');

// Unregister when done:
AnimationTracker.instance.unregisterAnimation('fadeIn');
```

```
⚠️ Frame rendering took 45ms.
Suggestion: Avoid expensive operations during animation.
```

---

## 🧪 Performance Metrics API

Access metrics programmatically:

```dart
final metrics = PerformanceOptimizer.metrics;

print(metrics.fps);            // Current FPS
print(metrics.memoryUsageMB);  // Memory in MB
print(metrics.totalRebuilds);  // Total rebuild count
print(metrics.jankFrames);     // Jank frame count
print(metrics.warningCount);   // Active warnings
```

Get a full snapshot:

```dart
final snapshot = metrics.snapshot();
print(snapshot); // Complete metrics at a point in time
```

---

## ⚙️ Configuration Options

```dart
PerformanceOptimizer(
  enabled: true,
  trackRebuilds: true,
  trackMemory: true,
  trackAnimations: true,
  trackWidgetSize: true,
  trackWidgetDepth: true,
  trackSetState: true,
  showDashboard: true,
  warningThreshold: 16,           // ms
  rebuildWarningCount: 60,        // rebuilds in window
  maxWidgetDepth: 30,             // max tree depth
  dashboardPosition: DashboardPosition.topRight,
  dashboardOpacity: 0.92,
  logWarnings: true,
  onWarning: (warning) {
    print(warning.message);
  },
  onFrame: (frame) {
    print(frame.buildTime);
    print(frame.rasterTime);
  },
  child: MyApp(),
);
```

Or use the `PerformanceConfig` object:

```dart
PerformanceOptimizer(
  config: PerformanceConfig(
    enabled: true,
    showDashboard: true,
    warningThreshold: Duration(milliseconds: 16),
  ),
  child: MyApp(),
);
```

---

## 🎯 Optimization Suggestions Engine

The package provides automatic suggestions:

| Issue | Suggestion |
|-------|-----------|
| Too many rebuilds | Use const widgets, ValueListenableBuilder |
| Heavy list | Use ListView.builder |
| Large images | Use cached images with size limits |
| Slow animation | Use RepaintBoundary |
| Deep tree | Split into smaller widgets |
| Frequent setState | Use ValueNotifier or state management |
| Memory leak | Dispose controllers and subscriptions |

Generate a report:

```dart
final report = PerformanceOptimizer.report;
print(report);
```

---

## 🧩 Performance Inspector Widget

Wrap specific widgets for targeted analysis:

```dart
PerformanceInspector(
  name: "HomeScreen",
  child: HomeScreen(),
);
```

Features:
- Tracks rebuild count for that widget
- Shows a visual badge with rebuild count
- Measures widget tree depth
- Optional callback on each rebuild

```dart
PerformanceInspector(
  name: "ProductList",
  showBadge: true,
  onRebuild: (count) => print('Rebuilt $count times'),
  child: ProductList(),
);
```

---

## 📊 Frame Timing Analysis

Access frame timing:

```dart
PerformanceOptimizer(
  onFrame: (frame) {
    print(frame.buildTime);   // Build phase duration
    print(frame.rasterTime);  // Raster phase duration
    print(frame.totalTime);   // Total frame time
  },
  child: MyApp(),
);
```

---

## 🔔 Performance Alerts

Listen for warnings:

```dart
PerformanceOptimizer.addWarningListener((warning) {
  print(warning.message);
  print(warning.type);       // WarningType enum
  print(warning.severity);   // WarningSeverity enum
  print(warning.suggestion); // Suggested fix
});
```

---

## 📈 Performance Score

Get an overall app performance score:

```dart
final score = PerformanceOptimizer.score;

print(score.total);        // 0-100
print(score.grade);        // A+, A, B, C, D, F
print(score.fpsScore);     // FPS component
print(score.memoryScore);  // Memory component
print(score.rebuildScore); // Rebuild component
print(score.jankScore);    // Jank component
```

Score weights:
- **FPS**: 25%
- **Jank**: 20%
- **Rebuilds**: 15%
- **Memory**: 15%
- **Warnings**: 10%
- **SetState**: 7.5%
- **Widget Depth**: 7.5%

---

## 🛠 Debug Mode Only (Recommended)

```dart
import 'package:flutter/foundation.dart';

PerformanceOptimizer(
  enabled: kDebugMode,
  child: MyApp(),
);
```

---

## 🧱 Architecture Overview

Internally uses:
- `SchedulerBinding.addTimingsCallback` — Frame timing
- `FrameTiming` API — Build & raster time analysis
- Widget binding observers — Lifecycle tracking
- Custom rebuild tracker — Per-widget rebuild counting
- Memory tracking hooks — Resource lifecycle monitoring
- Diagnostics tree analysis — Widget tree depth measurement
- Suggestion engine — Pattern-based recommendation system

---

## 🧪 Supported Platforms

| Platform | Supported |
|----------|-----------|
| Android | ✅ |
| iOS | ✅ |
| Web | ✅ |
| macOS | ✅ |
| Windows | ✅ |
| Linux | ✅ |

---

## 🔒 Privacy

The package:
- ✔ Does not collect user data
- ✔ Works entirely locally
- ✔ No analytics or tracking
- ✔ Safe for production debugging (when enabled)

---

## ⚠️ Known Limitations

- Memory leak detection is heuristic-based (patterns, not definitive)
- Deep widget analysis may add slight overhead in debug mode
- Best results in debug/profile mode
- Memory usage metrics vary by platform

---

## 📅 Roadmap

Upcoming features:
- 📊 Per-component performance breakdown
- 📡 Network activity monitoring
- 🖼 Image optimization analysis (over-sized assets)
- 🔌 Plugin / Native-side performance tracking
- 🧪 Multi-frame jank regression testing

---

### 🤖 AI-Powered Suggestions

The optimizer includes a heuristic AI engine supplemented by **Gemini 1.5 Flash** for deep architectural analysis. It automatically identifies complex patterns and suggests granular fixes.

```dart
// The engine is powered by Gemini for deep insights
AISuggestionService.instance.enabled = true;
// You can override the default API Key if needed
AISuggestionService.instance.apiKey = 'YOUR_CUSTOM_KEY';
```

### 🧪 CI/CD Performance Testing

Ensure your app stays fast with automated performance assertions in your widget tests:

```dart
testWidgets('Performance regression test', (tester) async {
  await PerformanceTestHelper.runApp(tester, MyApp());
  await tester.pumpAndSettle();

  PerformanceTestHelper.assertFps(min: 60);
  PerformanceTestHelper.assertScore(minScore: 90);
});
```

### 🗺 Rebuild Heatmap

Visualize rebuild intensity directly on your UI. High-rebuild areas will glow from green to red.

```dart
PerformanceOptimizer(
  showHeatmap: true,
  child: MyApp(),
);
```

### 📈 Performance History Timeline

Track your app's performance trends over time with the historical timeline chart. This helps identify degradation over long sessions.

```dart
// The history is automatically recorded based on config.historyInterval
// View it in the "History" tab of the dashboard.
```

### ⚡ CPU & GPU Profiling

Get real-time snapshots of system-level performance. The optimizer provides estimated load for both the CPU (UI & Background tasks) and GPU (Rasterization).

```dart
final cpuLoad = ProfilingTracker.instance.estimatedCpuLoad;
final gpuLoad = ProfilingTracker.instance.estimatedGpuLoad;
```

---

## 🛠 devtools Extension

The package includes a built-in DevTools extension. When you run your app in debug mode and open Flutter DevTools, you'll see a new "Performance Optimizer" tab with all the dashboard features available in a full-screen desktop view.

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Submit a pull request

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⭐ Support

If you find this package useful:

- ⭐ Star the repository
- 🐛 Report issues
- 💡 Suggest features
- 📦 Share with other developers

---

## 🏆 Why This Package Is Special

Unlike basic FPS monitors, this package:

- ✔ **Detects root causes** — not just symptoms
- ✔ **Explains problems** — with detailed context
- ✔ **Suggests fixes** — with actual code examples
- ✔ **Works automatically** — minimal setup required
- ✔ **Scores your app** — quantified performance tracking
- ✔ **Beautiful dashboard** — premium developer experience

**This makes it a next-generation Flutter performance tool.** ⚡
