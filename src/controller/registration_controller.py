"""Flask Controller cho Module 1: đăng ký thành viên.

Chỉ xử lý HTTP, CSRF, điều hướng và thông báo. Mọi kiểm tra nghiệp vụ,
Argon2id và transaction đều do RegistrationService thực hiện.

Blueprint sẽ được đăng ký vào app.py ở bước sau; template register.html
sẽ được xây dựng riêng, không nằm trong phạm vi file này.
"""
from __future__ import annotations

import secrets

from flask import (
    Blueprint,
    current_app,
    flash,
    redirect,
    render_template,
    request,
    session,
    url_for,
)

from src.model.registration_service import (
    AlreadyRegisteredError,
    GuestVerificationRequiredError,
    RegistrationConflictError,
    RegistrationRetryableError,
    RegistrationService,
    RegistrationStorageError,
    RegistrationValidationError,
    UsernameAlreadyExistsError,
)

registration_bp = Blueprint("registration", __name__)

_CSRF_SESSION_KEY = "neIumUmwnh3OjL1n5i93"
_FORM_FIELDS = (
    "full_name", 
    "phone", 
    "username", 
    "email", 
    "address"
)


def _csrf_token() -> str:
    """Sinh token CSRF lưu trong Flask session (cần SECRET_KEY của ứng dụng)."""
    token = session.get(_CSRF_SESSION_KEY)
    if not isinstance(token, str) or len(token) < 32:
        token = secrets.token_urlsafe(32)
        session[_CSRF_SESSION_KEY] = token
    return token


def _submitted_csrf_is_valid() -> bool:
    """So sánh token từ form với token trong session bằng constant-time compare."""
    expected = session.get(_CSRF_SESSION_KEY)
    submitted = request.form.get("csrf_token", "")
    return (
        isinstance(expected, str)
        and isinstance(submitted, str)
        and 0 < len(submitted) <= 128
        and secrets.compare_digest(submitted, expected)
    )


def _render_form(
        *, 
        error: str | None = None, 
        status: int = 200
) -> tuple[str, int]:
    """Render lại form; giữ thông tin không nhạy cảm, không trả lại mật khẩu."""
    form_values = (
        {field: request.form.get(field, "").strip() for field in _FORM_FIELDS}
        if request.method == "POST"
        else {}
    )
    html = render_template(
        "register.html",
        title="Đăng ký thành viên",
        csrf_token=_csrf_token(),
        form_values=form_values,
        error=error,
    )
    return html, status


@registration_bp.route("/register", methods=("GET", "POST"))
def register():
    """GET: hiện form; POST: chuyển dữ liệu sang RegistrationService."""
    if request.method == "GET":
        return _render_form()

    # Không gửi yêu cầu tới Service khi form thiếu/sai CSRF.
    if not _submitted_csrf_is_valid():
        session.pop(_CSRF_SESSION_KEY, None)
        return _render_form(
            error="Phiên biểu mẫu không hợp lệ. Vui lòng tải lại trang và thử lại.",
            status=400,
        )

    try:
        RegistrationService().register(
            full_name=request.form.get("full_name", ""),
            phone=request.form.get("phone", ""),
            username=request.form.get("username", ""),
            password=request.form.get("password", ""),
            email=request.form.get("email"),
            address=request.form.get("address"),
        )
    except RegistrationValidationError as exc:
        return _render_form(error=str(exc), status=400)
    except (
        UsernameAlreadyExistsError,
        GuestVerificationRequiredError,
        AlreadyRegisteredError,
        RegistrationConflictError,
    ) as exc:
        return _render_form(error=str(exc), status=409)
    except RegistrationRetryableError as exc:
        current_app.logger.warning("Registration transaction needs retry")
        return _render_form(error=str(exc), status=503)
    except RegistrationStorageError:
        # Không để lộ SQL, mật khẩu hay chi tiết lỗi kết nối cho người dùng.
        current_app.logger.error("Registration storage error")
        return _render_form(
            error="Chưa thể hoàn tất đăng ký. Vui lòng thử lại sau.", status=503
        )

    # POST-Redirect-GET: tránh trình duyệt gửi lại form khi tải lại trang.
    session.pop(_CSRF_SESSION_KEY, None)
    flash("Đăng ký thành viên thành công.", "success")
    return redirect(url_for("registration.register"), code=303)
