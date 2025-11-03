# neom_media_player
neom_media_player is a dedicated module within the Open Neom ecosystem, primarily responsible
for providing robust media playback functionalities. It centralizes the logic and UI components
for playing various types of media, including local videos and YouTube videos, ensuring
a consistent and high-quality  playback experience across the application.

This module is designed to abstract the complexities of media playback, allowing other modules
(like neom_posts and neom_timeline) to easily integrate video and YouTube content without needing
to handle the underlying player implementations. It adheres to Open Neom's Clean Architecture principles
by providing a clear service interface (MediaPlayerService in neom_core) for playback control,
while encapsulating the concrete player implementations. Its focus on seamless media consumption
aligns with the Tecnozenism philosophy of enriching digital interactions.

🌟 Features & Responsibilities
neom_media_player provides a comprehensive set of functionalities for media playback:
•	Video Playback: Offers dedicated widgets (NeomVideoPlayer) for playing local or network-based video files,
    including basic controls (play/pause, mute, progress indicator) and full-screen capabilities.
•	YouTube Video Playback: Provides dedicated widgets (NeomYoutubePlayer) for embedding and playing
    YouTube videos, including standard controls and full-screen options.
•	Full-Screen Media Display: Includes dedicated pages (FullScreenImagePage, FullScreenVideoPage)
    for viewing images and videos in full-screen mode, enhancing the immersive content experience.
•	Playback Control & Management: The MediaPlayerController manages the lifecycle of video and YouTube
    player controllers, including initialization, play/pause, and disposal.
•	Visibility-Based Playback: Implements logic (visibleVideoAction) to automatically play videos
    when they are visible on screen and pause them when they scroll out of view,
    optimizing performance and user experience in feeds.
•	Playback Speed Control: Provides options for adjusting the playback speed of videos.
•	Global Key Management: Manages GlobalKey instances for video and YouTube players, allowing for 
    unique identification and control of multiple player instances across the application.
•	Spotify Integration (Metadata): Stores and provides Spotify track image URLs, enabling neom_posts
    to display relevant visuals for Spotify content.

🛠 Technical Highlights / Why it Matters (for developers)
For developers, neom_media_player serves as an excellent case study for:
•	External Player Library Integration: Demonstrates effective integration of powerful third-party Flutter
    packages like video_player and youtube_player_flutter for robust media playback.
•	GetX for State Management: Utilizes GetX's MediaPlayerController for managing reactive state related
    to playback (e.g., isPlaying, isInitialized) and orchestrating player actions.
•	Service-Oriented Architecture: Implements the MediaPlayerService interface (defined in neom_core),
    showcasing how concrete media playback functionalities are exposed through an abstraction,
    allowing other modules to consume them without direct coupling.
•	Widget-Controller Interaction: Illustrates how StatefulWidgets (NeomVideoPlayer, NeomYoutubePlayer)
    manage their internal player controllers and register/unregister them with a GetX controller
    (MediaPlayerController) for centralized management.
•	Performance Optimization: Implements visibility-based playback to efficiently manage resources by pausing off-screen videos.
•	UI for Media Playback: Provides examples of building custom video player controls and full-screen viewing experiences.
•	Global Key Usage: Demonstrates the practical application of GlobalKey for uniquely identifying and controlling
    specific player instances in a dynamic list (like a timeline).

How it Supports the Open Neom Initiative
neom_media_player is vital to the Open Neom ecosystem and the broader Tecnozenism vision by:
•	Enabling Rich Multimedia Content: Provides the foundational capabilities for playing various media types,
    making the platform more engaging and dynamic for users.
•	Enhancing User Experience: Ensures a smooth, high-quality, and optimized media playback experience,
    crucial for content consumption and user satisfaction.
•	Supporting Digital Expression: Allows users to share and consume video and YouTube content seamlessly,
    aligning with the Tecnozenism principle of conscious digital expression.
•	Facilitating Research & Biofeedback: The ability to play diverse media could be leveraged for displaying
    visual data or guided content relevant to neuroscientific research and biofeedback applications.
•	Showcasing Modularity: As a specialized, self-contained module, it exemplifies Open Neom's "Plug-and-Play" architecture,
    demonstrating how complex functionalities can be built independently and integrated into the broader application.

🚀 Usage
This module provides widgets (NeomVideoPlayer, NeomYoutubePlayer) that can be used directly in UI components 
(e.g., PostDisplayCard in neom_posts). Its MediaPlayerController implements MediaPlayerService (from neom_core), 
allowing other modules to control playback and retrieve player-related data through the service interface. 
It also offers routes for full-screen media viewing.

📦 Dependencies
neom_media_player relies on neom_core for core services, models, and routing constants, and on neom_commons
for reusable UI components, themes, and utility functions. It directly depends on video_player
and youtube_player_flutter for its core playback functionalities.

🤝 Contributing
We welcome contributions to the neom_media_player module! If you're passionate about media playback,
performance optimization, integrating new player types, or enhancing the user's content consumption experience,
your contributions can significantly enrich Open Neom.

To understand the broader architectural context of Open Neom and how neom_media_player fits into the overall
vision of Tecnozenism, please refer to the main project's MANIFEST.md.

For guidance on how to contribute to Open Neom and to understand the various levels of learning and engagement
possible within the project, consult our comprehensive guide: Learning Flutter Through Open Neom: A Comprehensive Path.

📄 License
This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
