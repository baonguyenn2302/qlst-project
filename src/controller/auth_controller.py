"""Flask Controller cho dang nhap va dang xuat."""

from __future__ import annotations

import secrets
from functools import wraps

from flask import (
    Blueprint,
    abort,
    current_app,
    redirect,
    render_template,
    request,
    session,
    url_for,
)
from pymysql.err import MySQLError

from src.model.authentication_service import AuthenticationService


auth_bp = Blueprint("auth", __name__)

_AUTH_CSRF_SESSION_KEY = "auth_csrf_token"

_LOGIN_ERROR = "Tên đăng nhập hoặc mật khẩu không chính xác."
_CSRF_ERROR = "Phiên biểu mẫu không hợp lệ. Vui lòng tải lại trang và thử lại."


def _csrf_token() -> str:
    """Tao token CSRF rieng cho dang nhap va dang xuat."""
    token = session.get(_AUTH_CSRF_SESSION_KEY)

    if not isinstance(token, str) or len(token) < 32:
        token = secrets.token_urlsafe(32)
        session[_AUTH_CSRF_SESSION_KEY] = token

    return token


def _submitted_csrf_is_valid() -> bool:
    """Kiem tra CSRF bang constant-time comparison."""
    expected = session.get(_AUTH_CSRF_SESSION_KEY)
    submitted = request.form.get("csrf_token", "")

    return (
        isinstance(expected, str)
        and isinstance(submitted, str)
        and 0 < len(submitted) <= 128
        and secrets.compare_digest(submitted, expected)
    )


def _render_login(
    *,
    error: str | None = None,
    username: str = "",
    status: int = 200,
) -> tuple[str, int]:
    """Hien thi form; khong tra lai mat khau."""
    html = render_template(
        "login.html",
        title="Đăng nhập",
        csrf_token=_csrf_token(),
        username=username,
        error=error,
    )
    return html, status


@auth_bp.route("/login", methods=("GET", "POST"))
def login():
    """GET hien thi form; POST xac thuc tai khoan."""
    if request.method == "GET":
        return _render_login()

    username = request.form.get("username", "").strip()

    if not _submitted_csrf_is_valid():
        session.pop(_AUTH_CSRF_SESSION_KEY, None)

        return _render_login(
            error=_CSRF_ERROR,
            username=username,
            status=400,
        )

    password = request.form.get("password", "")

    try:
        user_id = AuthenticationService().authenticate(
            username,
            password,
        )
    except MySQLError:
        current_app.logger.error("Authentication storage error")

        return _render_login(
            error="Chưa thể đăng nhập lúc này. Vui lòng thử lại sau.",
            username=username,
            status=503,
        )

    if user_id is None:
        return _render_login(
            error=_LOGIN_ERROR,
            username=username,
            status=401,
        )

    # Xoa trang thai session truoc khi xac thuc thanh cong.
    session.clear()

    # Chi luu dinh danh tai khoan, khong luu password/hash.
    session["user_id"] = user_id
    session.permanent = True

    # Tao token CSRF moi sau khi session duoc lam moi.
    _csrf_token()

    # Dieu huong co dinh, khong su dung URL next tu nguoi dung.
    return redirect(url_for("entry"), code=303)


@auth_bp.post("/logout")
def logout():
    """POST logout: bat buoc CSRF, xoa session va redirect."""
    if not _submitted_csrf_is_valid():
        abort(400)

    session.clear()

    return redirect(url_for("auth.login"), code=303)


def require_revenue_access(view_func):
    """Kiem tra quyen xem bao cao truoc khi goi view."""

    @wraps(view_func)
    def protected_view(*args, **kwargs):
        user_id = session.get("user_id")

        # Chua dang nhap: khong xoa CSRF cua form dang ky.
        if user_id is None:
            return redirect(url_for("auth.login"))

        # Dinh danh phien sai kieu hoac khong hop le.
        if type(user_id) is not int or user_id <= 0:
            session.clear()
            return redirect(url_for("auth.login"))

        try:
            decision = AuthenticationService().revenue_access(
                user_id
            )
        except MySQLError:
            current_app.logger.exception(
                "Revenue authorization storage error"
            )
            abort(503)

        # Tai khoan da bi khoa, ho so khong hop le
        # hoac tai khoan khong con ton tai.
        if decision == "login_required":
            session.clear()
            return redirect(url_for("auth.login"))

        # Da dang nhap nhung khong co quyen bao cao.
        if decision != "allowed":
            abort(403)

        # Chi admin/manager hop le moi den duoc view.
        return view_func(*args, **kwargs)

    return protected_view
