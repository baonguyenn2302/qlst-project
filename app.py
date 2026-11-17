"""Diem vao Flask. Chua cai dat Module 1 hoac Module 2."""
from pathlib import Path

from flask import Flask, jsonify, render_template
from jinja2 import ChoiceLoader, FileSystemLoader

from src.config import PROJECT_ROOT, get_flask_secret_key


def create_app() -> Flask:
    view_root = PROJECT_ROOT / "view"
    app = Flask(
        __name__,
        template_folder=str(view_root / "templates"),
        static_folder=str(view_root / "static"),
        static_url_path="/static",
    )
    # Ho tro view/base.html co san va view/templates/* khong can doi thu muc.
    app.jinja_loader = ChoiceLoader([
        FileSystemLoader(str(view_root / "templates")),
        FileSystemLoader(str(view_root)),
    ])
    app.config["SECRET_KEY"] = get_flask_secret_key()

    @app.get("/")
    def home():
        return render_template("index.html", title="Sieu thi dien may")

    @app.get("/health")
    def health():
        # Chi xac nhan Flask dang chay; KHONG dai dien ket noi MySQL.
        return jsonify(status="ok", component="flask")

    return app


if __name__ == "__main__":
    application = create_app()
    application.run(host="127.0.0.1", port=5000, debug=False)
