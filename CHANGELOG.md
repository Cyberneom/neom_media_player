### 1.1.0 Architectural Refinements & Playback Specialization
This release for neom_media_player introduces significant architectural enhancements, solidifying its role as the central module for all media playback functionalities within the Open Neom ecosystem. The primary focus has been on achieving greater modularity, testability, and a clear separation of concerns, in line with the overarching Clean Architecture principles.

Key Architectural & Feature Improvements:

Comprehensive Service Decoupling:

The MediaPlayerController now implements the MediaPlayerService interface (defined in neom_core), ensuring that all media playback functionalities are exposed through a clear abstraction.

This promotes the Dependency Inversion Principle (DIP), allowing other modules (e.g., neom_timeline, neom_posts) to interact with media playback services without direct coupling to the concrete MediaPlayerController implementation.

Module-Specific Translations:

Introduced PlayerTranslationConstants to centralize and manage all UI text strings specific to media player functionalities. This ensures improved localization, maintainability, and consistency with Open Neom's global strategy.

Examples of new translation keys include: playbackSpeed, listenOnSpotify.

Centralized Media Playback Management:

neom_media_player now fully encapsulates the integration and management of external media player libraries (video_player, youtube_player_flutter).

It provides dedicated widgets (NeomVideoPlayer, NeomYoutubePlayer) for displaying and controlling video playback, handling their lifecycle (initialization, play/pause, disposal).

Implements a centralized mechanism (registerVideoKeyController, registerYouTubeKeyController) to manage multiple player instances across the application, particularly for features like visibility-based auto-play/pause in feeds.

Enhanced Media Playback Features:

Includes full-screen capabilities for both images and videos.

Implements logic for visibility-based video playback optimization, pausing off-screen videos to save resources.

Provides controls for adjusting video playback speed.

Integration with Global Architectural Changes:

Adopts the updated service injection patterns established in neom_core's recent refactor, ensuring consistent dependency management across the ecosystem.

Benefits from consolidated utilities and shared UI components from neom_commons.

Overall Benefits of this Major Refactor:

Maximized Decoupling: neom_media_player is now a highly independent module, focused purely on media playback, with clear contracts for interacting with other specialized modules.

Increased Testability: The extensive use of service interfaces makes the MediaPlayerController and its logic much easier to unit test in isolation.

Improved Maintainability & Scalability: Clearer responsibilities and reduced coupling make the module simpler to understand, debug, and extend for future playback features or new media types.

Enhanced User Experience: Seamless, high-quality, and optimized media playback contributes significantly to user engagement and content consumption.
