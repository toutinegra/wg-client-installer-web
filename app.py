from flask import Flask, render_template, request, send_file, abort
import os
import datetime
import subprocess

app = Flask(__name__)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_PS1 = os.path.join(BASE_DIR, "template.ps1")
OUTPUT_DIR = os.path.join(BASE_DIR, "output")
ICON_PATH = os.path.join(BASE_DIR, "icon.ico")

os.makedirs(OUTPUT_DIR, exist_ok=True)

@app.route("/")
def index():
    return render_template(
        "index.html",
        year=datetime.datetime.now().year,
        version="1.0"
    )

@app.route("/generate", methods=["POST"])
def generate():
    data = request.form

    required_fields = [
        "interface_name",
        "client_ip",
        "dns",
        "server_public_key",
        "allowed_ips",
        "endpoint",
        "keepalive"
    ]

    for field in required_fields:
        if field not in data or not data[field].strip():
            abort(400, f"Campo ausente: {field}")

    with open(TEMPLATE_PS1, "r", encoding="utf-8") as f:
        script = f.read()

    replacements = {
        "{{INTERFACE_NAME}}": data["interface_name"],
        "{{CLIENT_IP}}": data["client_ip"],
        "{{DNS}}": data["dns"],
        "{{SERVER_PUBLIC_KEY}}": data["server_public_key"],
        "{{ALLOWED_IPS}}": data["allowed_ips"],
        "{{ENDPOINT}}": data["endpoint"],
        "{{KEEPALIVE}}": data["keepalive"]
    }

    for k, v in replacements.items():
        script = script.replace(k, v)

    ps1_path = os.path.join(OUTPUT_DIR, "installer.ps1")
    exe_path = os.path.join(OUTPUT_DIR, "WireGuard-Client-Installer.exe")

    with open(ps1_path, "w", encoding="utf-8") as f:
        f.write(script)

    # Geração do EXE com ícone
    subprocess.run([
        "powershell",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-Command",
        (
            f"Invoke-PS2EXE "
            f"'{ps1_path}' "
            f"'{exe_path}' "
            f"-NoConsole "
            f"-RequireAdmin "
            f"-IconFile '{ICON_PATH}'"
        )
    ], check=True)

    return send_file(exe_path, as_attachment=True)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
