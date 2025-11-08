#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import datetime as dt
import os
import subprocess
import sys
import zipfile
import shutil

def fail(msg: str, code: int = 1):
    print(f"[ERROR] {msg}", file=sys.stderr)
    sys.exit(code)

def get_repo_root() -> str | None:
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True
        ).stdout.strip()
        return out if out else None
    except Exception:
        return None

def get_included_files(repo_root: str) -> list[str]:
    """
    Возвращает список файлов (относительные пути от корня репо),
    учитывающих .gitignore: tracked + untracked неигнорируемые.
    """
    try:
        proc = subprocess.run(
            ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
            cwd=repo_root,
            capture_output=True,
            check=True
        )
    except FileNotFoundError:
        fail("Не найден 'git' в PATH. Установи Git или добавь его в PATH.")
    except subprocess.CalledProcessError as e:
        stderr = (e.stderr or b"").decode(errors="ignore").strip()
        fail(f"Не удалось получить список файлов через git ls-files: {stderr or e}")

    raw = proc.stdout or b""
    items = [p.decode("utf-8", "surrogateescape") for p in raw.split(b"\x00") if p]
    # На всякий случай убираем всё под .git/ на любой глубине
    filtered = [p for p in items if "/.git/" not in p and not p.startswith(".git/")]
    return filtered

def default_zip_name(repo_root: str) -> str:
    folder = os.path.basename(os.path.normpath(repo_root))
    ts = dt.datetime.now().strftime("%Y%m%d-%H%M")
    return f"{folder}-{ts}.zip"

def main():
    parser = argparse.ArgumentParser(
        description="Архивирует проект в ZIP с учётом .gitignore (через git ls-files) и кладёт архивы в папку archives."
    )
    parser.add_argument("--name", dest="name",
                        help="Имя ZIP-файла (например, backup.zip). По умолчанию: <ИмяПапки>-YYYYMMDD-HHMM.zip")
    parser.add_argument("--dir", dest="out_dir", default="archives",
                        help="Папка для архивов относительно корня репозитория. По умолчанию: archives")
    parser.add_argument("--open", dest="open_folder", action="store_true",
                        help="Открыть папку с архивом по завершении (Windows).")
    args = parser.parse_args()

    repo_root = get_repo_root()
    if not repo_root:
        fail("Похоже, это не git-репозиторий. Зайди в папку репозитория (или выполни 'git init').")

    files = get_included_files(repo_root)
    if not files:
        fail("Список файлов пуст. Возможно, всё проигнорировано .gitignore или ты не в корне проекта.")

    # Папка вывода архивов
    out_dir_abs = os.path.join(repo_root, args.out_dir)
    os.makedirs(out_dir_abs, exist_ok=True)

    # Имя архива
    zip_name = args.name if args.name else default_zip_name(repo_root)
    zip_name = os.path.basename(zip_name)  # на случай, если передан путь
    if not zip_name.lower().endswith(".zip"):
        zip_name += ".zip"

    out_zip = os.path.abspath(os.path.join(out_dir_abs, zip_name))
    out_pdf = os.path.abspath(out_zip + ".pdf")  # «двойник» с .pdf

    # Исключим итоговые файлы (и .zip, и .pdf) из списка, если их относительные пути внезапно попадут
    rel_zip = os.path.relpath(out_zip, repo_root).replace("\\", "/")
    rel_pdf = os.path.relpath(out_pdf, repo_root).replace("\\", "/")
    files = [f for f in files if f != rel_zip and f != rel_pdf]

    # Чистим старые файлы, если уже есть
    for path in (out_zip, out_pdf):
        if os.path.exists(path):
            try:
                os.remove(path)
            except Exception as e:
                fail(f"Не удалось удалить существующий файл '{path}': {e}")

    # Упаковка
    try:
        with zipfile.ZipFile(out_zip, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9, allowZip64=True) as zf:
            for relpath in files:
                fullpath = os.path.join(repo_root, relpath)
                if os.path.isfile(fullpath):
                    arcname = relpath.replace("\\", "/")
                    zf.write(fullpath, arcname=arcname)
        print(f"[OK] ZIP создан: {out_zip}")
        print(f"[i] Упаковано файлов: {len(files)}")
    except Exception as e:
        fail(f"Ошибка при создании ZIP: {e}")

    # Создаём «двойник» с расширением .pdf (байт-в-байт копия ZIP)
    try:
        shutil.copyfile(out_zip, out_pdf)
        print(f"[OK] PDF-копия создана: {out_pdf}")
    except Exception as e:
        fail(f"Не удалось создать PDF-копию: {e}")

    # Открыть папку с архивами (по желанию)
    if args.open_folder and os.name == "nt":
        try:
            os.startfile(out_dir_abs)  # только Windows
        except Exception:
            pass

if __name__ == "__main__":
    main()