# YouTube Live Chat Overlay

**Live Chat Overlay Project**  
This is a Lua-based live chat overlay system for MPV, which initializes and updates a real-time chat overlay by reading chat messages via a socket. To start, call the `Main` function with the port number and interval.

## Installation

To use this project, you’ll need to install the `chat-downloader` Python package:

```bash
pip install chat-downloader
```

## Usage

1. Download the repository and place it in your MPV `scripts` folder.
2. The script automatically activates for YouTube links matching the regex `youtu%.be/([%w_-]+)`. You can modify this regex if you’d like it to work with other patterns.