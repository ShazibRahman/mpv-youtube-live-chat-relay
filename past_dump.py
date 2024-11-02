"""
Download past chat and save output to .txt file which is then used as a subtitle for mpv
"""    
import datetime
import pathlib
import sys
import textwrap
from chat_downloader import ChatDownloader
from chat_downloader.errors import NoChatReplay


def replace_emotes(message_data, message_text):
    """Replace emote names with their corresponding IDs in the message text."""
    for emote in message_data.get("emotes", []):
        if emote.get("name") in message_text and not emote.get("is_custom_emoji", True):
            message_text = message_text.replace(emote["name"], emote.get("id", ""))
    return message_text


def extract_badge_titles(badges):
    """Combine all badge titles for a user into a single suffix string."""
    return "".join(badge.get("title", "") for badge in badges)


def generate_user_color(username, badge_suffix):
    """Create a color code based on the username and badge suffix."""
    identifier = badge_suffix or username
    # return "{:06x}".format(hash(identifier) % 16777216)
    return  f"{hash(identifier) % 16777216:06x}"


def format_message(username, message_text, badge_suffix, color_code):
    """Format the message into a colored HTML-style line."""
    wrapped_text = "\n".join(textwrap.wrap(message_text, width=40))
    return (
        f'<font color="#{color_code}">{username} {badge_suffix}</font>: {wrapped_text}'
    )


def create_srt_entry(start_seconds, duration=1, text="", entry_number=1):
    """Generate an SRT entry with start time, duration, subtitle text, and entry number."""
    start_time = datetime.timedelta(seconds=start_seconds)
    end_time = datetime.timedelta(seconds=start_seconds + duration)

    start_str = str(start_time)[:-3].replace(".", ",")
    end_str = str(end_time)[:-3].replace(".", ",")

    return f"{entry_number}\n{start_str} --> {end_str}\n{text}\n"


def download_and_save_chat(stream_id, output_file):
    """Download chat messages from a YouTube stream and save them as subtitles in SRT format."""
    video_url = f"https://www.youtube.com/watch?v={stream_id}"
    chat_messages = ChatDownloader().get_chat(url=video_url)

    with output_file.open("w") as file:
        for entry_number, message_data in enumerate(chat_messages, start=1):
            timestamp = message_data.get("time_in_seconds", 0)
            if timestamp <= 0:
                continue

            author_data = message_data["author"]
            username = author_data["name"]
            message_text = replace_emotes(message_data, message_data["message"])

            badge_suffix = extract_badge_titles(author_data.get("badges", []))
            color_code = generate_user_color(username, badge_suffix)
            formatted_message = format_message(
                username, message_text, badge_suffix, color_code
            )

            srt_entry = create_srt_entry(
                start_seconds=timestamp,
                duration=2,
                text=formatted_message,
                entry_number=entry_number,
            )
            file.write(srt_entry)


def main():
    """Main function to initiate chat download and subtitle creation."""
    stream_id = sys.argv[1] if len(sys.argv) > 1 else "rQDF52_9Tn0"
    output_file = pathlib.Path(__file__).parent / f"{stream_id}.txt"
    try:
        download_and_save_chat(stream_id, output_file)
    except (NoChatReplay, KeyboardInterrupt):
        print("Chat replay not found.")


if __name__ == "__main__":
    main()
