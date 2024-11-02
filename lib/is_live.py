"""
check if a stream is live
"""

import sys
from chat_downloader import ChatDownloader
from chat_downloader.errors import NoChatReplay




def is_live(stream_id):
    """
    Check if a YouTube stream is live.
    Returns True if the stream is live, False otherwise."""
    url = f"https://www.youtube.com/watch?v={stream_id}"
    chat = ChatDownloader().get_chat(url=url)
    return chat.status == "live"


def main():
    """
    Main function to check if a stream is live.
    """
    stream_id = "rQDF52_9Tn0" if len(sys.argv) < 2 else sys.argv[1]
    live = -1
    try:
        live = is_live(stream_id)
    except NoChatReplay:
        pass
    print(int(live))


if __name__ == "__main__":
    main()
