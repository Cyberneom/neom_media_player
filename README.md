# neom_media_player

Media Playback module for the Open Neom ecosystem.

neom_media_player is a dedicated module responsible for providing robust media playback functionalities. It centralizes the logic and UI components for playing various types of media, including local videos and YouTube videos, ensuring a consistent and high-quality playback experience across the application.

This module abstracts the complexities of media playback, allowing other modules (like neom_posts and neom_timeline) to easily integrate video and YouTube content without handling the underlying player implementations. It adheres to Open Neom's Clean Architecture principles by providing a clear service interface (MediaPlayerService) for playback control.

## Features & Responsibilities

### Video Playback
- **NeomVideoPlayer**: Widget for local/network video files
- Basic controls (play/pause, mute, progress indicator)
- Full-screen capabilities
- Playback speed control

### YouTube Video Playback
- **NeomYoutubePlayer**: Embedded YouTube player widget
- Standard YouTube controls
- Full-screen options
- Quality selection

### Full-Screen Media Display
- **FullScreenImagePage**: Immersive image viewing
- **FullScreenVideoPage**: Immersive video playback
- Pinch-to-zoom support
- Swipe gestures

### Playback Control & Management
- MediaPlayerController lifecycle management
- Initialization, play/pause, disposal
- Global key management for multiple instances
- Visibility-based playback optimization

### Spotify Integration
- Track image URL storage
- Metadata display support
- "Listen on Spotify" integration

## Architecture

```
lib/
├── media_player_routes.dart
├── ui/
│   ├── media_player_controller.dart
│   ├── neom_video_player.dart
│   ├── neom_youtube_player.dart
│   └── full_screen/
│       ├── full_screen_image_controller.dart
│       ├── full_screen_image_page.dart
│       ├── full_screen_video_controller.dart
│       └── full_screen_video_page.dart
├── utils/
│   └── constants/
│       └── player_translation_constants.dart
└── neom_media_player.dart
```

## Dependencies

```yaml
dependencies:
  neom_core: ^2.0.0           # Core services and models
  neom_commons: ^2.0.0        # Shared UI components
  sint: ^1.0.0                # State management (SINT framework)
  video_player: ^2.9.2        # Native video playback
  youtube_player_flutter: ^9.1.1  # YouTube embedding
  chewie: ^1.10.0             # Video player controls
```

## Usage

### Video Player Widget

```dart
import 'package:neom_media_player/ui/neom_video_player.dart';

NeomVideoPlayer(
  videoUrl: 'https://example.com/video.mp4',
  autoPlay: false,
  showControls: true,
  onFullScreen: () => navigateToFullScreen(),
)
```

### YouTube Player Widget

```dart
import 'package:neom_media_player/ui/neom_youtube_player.dart';

NeomYoutubePlayer(
  youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  autoPlay: false,
  showControls: true,
)
```

### Full-Screen Navigation

```dart
// Navigate to full-screen video
Sint.toNamed(
  AppRouteConstants.fullScreenVideo,
  arguments: {'videoUrl': videoUrl},
);

// Navigate to full-screen image
Sint.toNamed(
  AppRouteConstants.fullScreenImage,
  arguments: {'imageUrl': imageUrl},
);
```

### MediaPlayerController

```dart
import 'package:neom_media_player/ui/media_player_controller.dart';

final controller = Sint.find<MediaPlayerController>();

// Register video player
controller.registerVideoKeyController(key, videoController);

// Visibility-based playback
controller.visibleVideoAction(key, isVisible: true);

// Get Spotify track image
String? imageUrl = controller.getSpotifyTrackImage(trackId);
```

## Visibility-Based Playback

The module automatically manages video playback based on screen visibility:

```dart
// In a scrollable list
VisibilityDetector(
  key: Key('video-$index'),
  onVisibilityChanged: (info) {
    final isVisible = info.visibleFraction > 0.5;
    controller.visibleVideoAction(videoKey, isVisible: isVisible);
  },
  child: NeomVideoPlayer(...),
)
```

## ROADMAP 2026

### Q1 2026 - Enhanced Player Features
- [ ] Picture-in-picture mode
- [ ] Background audio playback
- [ ] Chromecast/AirPlay support
- [ ] Playlist management

### Q2 2026 - Quality & Performance
- [ ] Adaptive bitrate streaming (HLS/DASH)
- [ ] Video caching/offline playback
- [ ] Buffer optimization
- [ ] Memory management improvements

### Q3 2026 - Advanced Controls
- [ ] Subtitle/closed caption support
- [ ] Multiple audio track selection
- [ ] Playback history
- [ ] Resume from last position

### Q4 2026 - Social Features
- [ ] Video reactions/comments overlay
- [ ] Share timestamp links
- [ ] Collaborative playlists
- [ ] Watch party sync

## State Management

neom_media_player uses the SINT framework (GetX replacement) for:
- Reactive playback state (isPlaying, isInitialized)
- Controller lifecycle management
- Global key registry for multiple players
- Cross-widget communication

## Contributing

We welcome contributions! If you're passionate about media playback, performance optimization, or integrating new player types, your contributions can significantly enrich Open Neom.

## License

This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
