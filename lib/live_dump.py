"""
Download live chat and stream it to clients via socket
"""

import pathlib
import socket
import sys
import textwrap
from chat_downloader import ChatDownloader
import os


# Template for displaying chat messages in mpv
CHAT_TEMPLATE = "{{\\c&H{username_color}&}}{username}{badge_suffix}\
{{\\c&H{default_color}&}} : {message_text}"


def format_message_text(content):
    """Wrap message text to a specified width for readability."""
    return "\n".join(textwrap.wrap(content, width=60))


def format_chat_message(username, badge_suffix, content, username_color):
    """Format the chat message into ASS format for mpv overlay."""
    wrapped_content = format_message_text(content)
    formatted_message = CHAT_TEMPLATE.format(
        username_color=username_color,
        default_color="FFFFFF",
        username=username,
        message_text=wrapped_content,
        badge_suffix=badge_suffix,
    )
    return formatted_message


def replace_emotes_in_message(chat_item, message_text):
    """Replace standard emotes with their corresponding IDs in the message text."""
    for emote in chat_item.get("emotes", []):
        if emote.get("name") in message_text and not emote.get("is_custom_emoji", True):
            message_text = message_text.replace(emote["name"], emote.get("id", ""))
    return message_text


def get_badge_suffix(badges):
    """Generate a string suffix based on user badges."""
    return " ".join(badge.get("title", "") for badge in badges)


def generate_color_code(username):
    """Generate a color code based on the username hash."""
    # return "{:06x}".format(hash(username) % 16777216)
    return f"{hash(username) % 16777216:06x}"


def handle_client_connection(client_socket, chat):
    """Send formatted chat messages to a connected client."""
    try:
        for chat_item in chat:
            message = format_chat_item(chat_item)
            if message:
                client_socket.sendall(message.encode("utf-8"))
                client_socket.sendall("\n".encode("utf-8"))
                # time.sleep(0.1)
    except (ConnectionResetError, BrokenPipeError):
        # print("Client connection closed.")
        ...
    finally:
        client_socket.close()


def format_chat_item(chat_item: dict):
    """Format a chat item for output, or return None if the content is empty."""
    username = chat_item["author"]["name"]
    content = replace_emotes_in_message(chat_item, chat_item.get("message", ""))

    if not content.strip():
        return None

    # badge_suffix = get_badge_suffix(chat_item["author"].get("badges", []))
    username_color = generate_color_code(username)
    return format_chat_message(username, "", content, username_color)


def start_server_socket(chat, port: int):
    """Initialize and handle socket server connections."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server_socket.bind(("127.0.0.1", port))
        server_socket.listen(1)
        # print(f"Server listening on port {port}")

        while True:
            try:
                client_socket, _ = server_socket.accept()
                # print(f"Connected to {client_address}")
                # print(f"Connected to {client_address}")
                handle_client_connection(client_socket, chat)
            except KeyboardInterrupt:
                # print("\nServer shutting down...")
                break


def download_live_chat_to_socket(stream_id, port):
    """Download live chat and stream it to clients via socket."""
    chat = ChatDownloader().get_chat(url=f"https://www.youtube.com/watch?v={stream_id}")
    start_server_socket(chat, port)


def download_live_chat_to_file(stream_id, file_path):
    """Download live chat and save messages to a file."""
    chat = ChatDownloader().get_chat(url=f"https://www.youtube.com/watch?v={stream_id}")
    try:
        write_chat_to_file(file_path, chat)
    except KeyboardInterrupt:
        if file_path.exists():
            file_path.unlink()


def write_chat_to_file(file_path, chat):
    """Write each formatted chat message to the specified file."""
    if file_path.exists():
        file_path.unlink()

    with file_path.open("a") as file:
        for chat_item in chat:
            message = format_chat_item(chat_item)
            if message:
                file.write(message + "\n")
                file.flush()


def main():
    """Main function to start chat download and output."""
    stream_id = sys.argv[1]
    port = int(sys.argv[2])
    # file_path = pathlib.Path(__file__).parent.joinpath(f"{stream_id}.txt")
    pid_file = pathlib.Path(__file__).parent.parent.joinpath(f"{stream_id}_pid.txt")
    if pid_file.exists():
        pid_file.unlink()
    pid_file.write_text(str(os.getpid()))




    # print(f"Starting streaming to socket on port {port}")
    download_live_chat_to_socket(stream_id, port)


if __name__ == "__main__":
    main()
    # print(CHAT_TEMPLATE)
