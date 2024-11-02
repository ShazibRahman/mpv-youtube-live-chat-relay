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
3. The auto trigger regex can be found inside the main.lua file inside the init function of the script.
4. In the lib/live_chat_overlay.lua file, you can modify the keybinds to your liking. [only for live streams]
5. It will automatically download the live chat messages and display them in the chat overlay. [only for live streams]
6. It has support for font size change, message timeout, and no of lines to be displayed, default values can be modified in the lib/live_chat_overlay.lua file. [only for live streams]
7. For the past stream all the chats are downloaded and displayed in the subtitles. [only for past streams]