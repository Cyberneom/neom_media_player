# Changelog

All notable changes to neom_media_player will be documented in this file.

## [1.4.1] - 2026-07-16
- Add mutual exclusion video/audio muting in MediaPlayerController.
- Handle dynamic mute state inside NeomVideoPlayer.

## [1.2.0] - 2025-02-09

### Changed
- Replaced deprecated `withOpacity()` with `withValues(alpha:)` in 4 files
- Updated full_screen_video_page.dart color handling
- Updated media_player_controller.dart gradient colors
- Updated neom_video_player.dart overlay colors
- README.md with comprehensive documentation and ROADMAP 2026

### Improved
- Code compliance with flutter_lints ^6.0.0
- Clean Architecture adherence

## [1.1.0] - 2025-01-15

### Added
- MediaPlayerController implementing MediaPlayerService interface
- PlayerTranslationConstants for localized UI strings
- Visibility-based playback optimization
- Playback speed control
- Global key management for multiple player instances

### Changed
- Migrated from GetX to SINT framework
- Updated SDK constraint to >=3.8.0 <4.0.0
- Comprehensive service decoupling (DIP compliance)

### Improved
- Module-specific translations (playbackSpeed, listenOnSpotify)
- Centralized media playback management
- Full-screen capabilities for images and videos

## [1.0.0] - 2024-08-15

### Added
- Initial release
- NeomVideoPlayer widget for local/network videos
- NeomYoutubePlayer widget for YouTube embedding
- FullScreenImagePage for image viewing
- FullScreenVideoPage for video playback
- Basic playback controls (play/pause, mute, progress)
- Integration with neom_core and neom_commons
- Spotify track image support
