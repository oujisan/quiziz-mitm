from mitmproxy import http
import re
import logging

# Inisialisasi logger independen
custom_logger = logging.getLogger("packet_dropper")
custom_logger.setLevel(logging.INFO)

# Menghapus handler lama jika script di-reload oleh mitmproxy
if custom_logger.hasHandlers():
    custom_logger.handlers.clear()

# mode='w' menimpa log lama. delay=False memaksa penulisan instan ke disk.
file_handler = logging.FileHandler("dropped_packets.log", mode='w', encoding='utf-8', delay=False)
file_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
custom_logger.addHandler(file_handler)

def request(flow: http.HTTPFlow) -> None:
    if flow.request.method != "POST":
        return

    if "fnl.wayground.com" in flow.request.pretty_host and "/_anserverv2/main/api/v1/frontend" in flow.request.path:
        msg = f"[AUTO-DROP] Intercepted frontend telemetry. URL: {flow.request.url}"
        custom_logger.warning(msg)
        flow.kill()
        return

    if "wayground.com" in flow.request.pretty_host and "player-infraction" in flow.request.path:
        match = re.search(r'/games/([a-f0-9]+)/player-infraction', flow.request.path)
        game_id = match.group(1) if match else "UNKNOWN_ID"
        
        msg = f"[AUTO-DROP] Blocked infraction report! Game ID: {game_id}"
        custom_logger.critical(msg)
        flow.kill()
        return