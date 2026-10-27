"""Verify the isolated NSIS test package and exact-file uninstall on Windows."""
import argparse
import json
from pathlib import Path
import subprocess
import time
import winreg

parser = argparse.ArgumentParser()
parser.add_argument('installer', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
target = (root / 'outputs/installer-test').resolve()
assert target.is_relative_to(root) and target.name == 'installer-test'
assert not target.exists(), 'Use a fresh test target; never delete an existing directory.'
assert args.installer.name.endswith('-Setup-Test.exe'), 'Only the isolated test package is allowed.'
key = r'Software\Microsoft\Windows\CurrentVersion\Uninstall\ClustterCore.UpdateTest.codex_thermometer'
try:
    winreg.OpenKey(winreg.HKEY_CURRENT_USER, key).Close()
    raise SystemExit('An isolated test registration already exists; inspect before continuing.')
except FileNotFoundError:
    pass
result = subprocess.run([str(args.installer.resolve()), '/S', '/D=' + str(target)], timeout=90)
assert result.returncode == 0, 'Installer failed'
assert (target / 'codex_thermometer.exe').is_file()
assert (target / 'flutter_windows.dll').is_file()
assert (target / 'vcruntime140.dll').is_file()
with winreg.OpenKey(winreg.HKEY_CURRENT_USER, key) as reg:
    assert winreg.QueryValueEx(reg, 'DisplayVersion')[0] == '0.1.0'
sentinel = target / 'preserve-user-file.txt'
sentinel.write_text('arquivo de teste do usuário; deve sobreviver', encoding='utf-8')
# _?= prevents NSIS moving the uninstaller to a background temp process.
result = subprocess.run([str(target / 'uninstall.exe'), '/S', '_?=' + str(target)], timeout=90)
assert result.returncode == 0, 'Uninstaller failed'
for _ in range(20):
    if not (target / 'codex_thermometer.exe').exists():
        break
    time.sleep(.1)
assert not (target / 'codex_thermometer.exe').exists()
assert sentinel.read_text(encoding='utf-8').startswith('arquivo de teste')
try:
    winreg.OpenKey(winreg.HKEY_CURRENT_USER, key).Close()
    raise AssertionError('Test uninstall registration was not removed')
except FileNotFoundError:
    pass
print(json.dumps({'install': 'passed', 'uninstall': 'passed', 'unknown_user_file_preserved': True}))
