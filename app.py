"""Diem vao Flask. Dang ky Blueprint Module 1 va Module 2."""
from datetime import timedelta
from pathlib import Path

from flask import Flask, abort, current_app, jsonify, redirect, render_template, session, url_for
from jinja2 import ChoiceLoader, FileSystemLoader
from pymysql.err import MySQLError

from src.config import PROJECT_ROOT, get_flask_secret_key
from src.controller.auth_controller import auth_bp, require_revenue_access
from src.controller.registration_controller import registration_bp
from src.controller.revenue_controller import revenue_bp
from src.model.authentication_service import AuthenticationService


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
    app.config.update(
        PERMANENT_SESSION_LIFETIME=timedelta(minutes=30),
        SESSION_REFRESH_EACH_REQUEST=False,
        SESSION_COOKIE_HTTPONLY=True,
        SESSION_COOKIE_SAMESITE="Lax",
    )

    # Gan cac Blueprint, route GET/POST da dinh nghia trong Controller.
    app.register_blueprint(auth_bp)
    app.register_blueprint(registration_bp)
    app.register_blueprint(revenue_bp)

    def _active_session_context():
        """Lay tai khoan hop le tu DB; khong tin role trong session."""
        user_id = session.get("user_id")
        if user_id is None:
            return None

        if type(user_id) is not int or user_id <= 0:
            session.clear()
            return None

        try:
            context = AuthenticationService().get_active_context(user_id)
        except MySQLError:
            current_app.logger.exception("Session lookup storage error")
            abort(503)

        if context is None:
            session.clear()
        return context

    @app.get("/")
    def entry():
        """Chuyen den trang phu hop sau khi dang nhap."""
        context = _active_session_context()
        if context is None:
            return redirect(url_for("auth.login"))
        if context["role_code"] == "customer":
            return redirect(url_for("account"))
        return redirect(url_for("menu"))

    @app.get("/menu")
    def menu():
        """Menu noi bo cho nhan vien dang hoat dong."""
        context = _active_session_context()
        if context is None:
            return redirect(url_for("auth.login"))
        if context["role_code"] == "customer":
            abort(403)

        return render_template(
            "menu.html",
            title="Sieu thi dien may",
            can_view_reports=context["role_code"] in ("admin", "manager"),
            logout_csrf_token=session.get("auth_csrf_token"),
        )

    @app.get("/account")
    def account():
        """Diem den toi thieu cho khach hang sau dang nhap."""
        context = _active_session_context()
        if context is None:
            return redirect(url_for("auth.login"))
        if context["role_code"] != "customer":
            abort(403)

        return render_template(
            "account.html",
            title="Tai khoan thanh vien",
            logout_csrf_token=session.get("auth_csrf_token"),
        )

    @app.get("/reports")
    @require_revenue_access
    def reports_menu():
        return render_template("reports.html")

    @app.get("/health")
    def health():
        # Chi xac nhan Flask dang chay; KHONG dai dien ket noi MySQL.
        return jsonify(status="ok", component="flask")

    return app


if __name__ == "__main__":
    application = create_app()
    application.run(host="127.0.0.1", port=5000, debug=False)
