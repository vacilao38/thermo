#include "flutter_window.h"

#include <optional>
#include <flutter/standard_method_codec.h>
#include "resource.h"

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  AddTray();
  window_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "clustter.thermo/window",
      &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    HWND hwnd = GetHandle();
    const bool* arg = call.arguments() ? std::get_if<bool>(call.arguments()) : nullptr;
    if (call.method_name() == "pin" && arg) {
      if (!SetWindowPos(hwnd, *arg ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0,
                       SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE)) {
        result->Error("window", "Não foi possível fixar a janela."); return;
      }
    } else if (call.method_name() == "compact" && arg) {
      if (*arg != compact_) {
        if (*arg) GetWindowRect(hwnd, &expanded_rect_);
        compact_ = *arg;
        const UINT dpi = GetDpiForWindow(hwnd);
        const int w = compact_ ? MulDiv(370, dpi, 96) : expanded_rect_.right - expanded_rect_.left;
        const int h = compact_ ? MulDiv(490, dpi, 96) : expanded_rect_.bottom - expanded_rect_.top;
        SetWindowPos(hwnd, nullptr, 0, 0, w, h, SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
      }
    } else if (call.method_name() == "state") {
      result->Success(flutter::EncodableValue(flutter::EncodableMap{
        {flutter::EncodableValue("visible"), flutter::EncodableValue(IsWindowVisible(hwnd) != FALSE)},
        {flutter::EncodableValue("pinned"), flutter::EncodableValue((GetWindowLongPtr(hwnd, GWL_EXSTYLE) & WS_EX_TOPMOST) != 0)},
        {flutter::EncodableValue("compact"), flutter::EncodableValue(compact_)}
      })); return;
    } else if (call.method_name() == "show") {
      ShowWindow(hwnd, SW_RESTORE); SetForegroundWindow(hwnd);
    } else if (call.method_name() == "tray") {
      if (!Shell_NotifyIconW(NIM_MODIFY, &tray_)) AddTray();
      if (!Shell_NotifyIconW(NIM_MODIFY, &tray_)) {
        result->Error("tray", "A bandeja está indisponível."); return;
      }
      ShowWindow(hwnd, SW_HIDE);
    } else {
      result->NotImplemented(); return;
    }
    result->Success();
  });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  Shell_NotifyIconW(NIM_DELETE, &tray_);
  window_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_GETMINMAXINFO: {
      auto info = reinterpret_cast<MINMAXINFO*>(lparam);
      const UINT dpi = GetDpiForWindow(hwnd);
      info->ptMinTrackSize.x = MulDiv(350, dpi, 96);
      info->ptMinTrackSize.y = MulDiv(420, dpi, 96);
      return 0;
    }
    case WM_APP + 71:
      if (lparam == WM_LBUTTONUP || lparam == WM_LBUTTONDBLCLK) {
        ShowWindow(hwnd, SW_RESTORE); SetForegroundWindow(hwnd);
      } else if (lparam == WM_RBUTTONUP) {
        HMENU menu = CreatePopupMenu();
        AppendMenuW(menu, MF_STRING, 1, L"Abrir Thermo");
        AppendMenuW(menu, MF_STRING, 2, L"Sair");
        POINT point; GetCursorPos(&point); SetForegroundWindow(hwnd);
        const int choice = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTBUTTON,
                                          point.x, point.y, 0, hwnd, nullptr);
        DestroyMenu(menu);
        if (choice == 1) { ShowWindow(hwnd, SW_RESTORE); SetForegroundWindow(hwnd); }
        if (choice == 2) PostMessage(hwnd, WM_CLOSE, 0, 0);
      }
      return 0;
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  if (message == RegisterWindowMessageW(L"TaskbarCreated")) AddTray();

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::AddTray() {
  tray_ = {};
  tray_.cbSize = sizeof(tray_);
  tray_.hWnd = GetHandle();
  tray_.uID = 1;
  tray_.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  tray_.uCallbackMessage = WM_APP + 71;
  tray_.hIcon = LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_APP_ICON));
  wcscpy_s(tray_.szTip, L"Thermo · Monitor de uso do Codex");
  Shell_NotifyIconW(NIM_ADD, &tray_);
}
