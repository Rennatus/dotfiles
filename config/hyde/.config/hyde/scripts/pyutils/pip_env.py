import sys
import os
import subprocess
import argparse
import shutil
import importlib

import wrapper.notify as notify
import xdg_base_dirs

# 当前文件为优先查找路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def get_venv_path():
    """Set up the virtual environment path and modify sys.path."""
    venv_path = os.path.join(xdg_base_dirs.xdg_state_home(), "hyde", "pip_env")
    site_packages_path = os.path.join(
        venv_path,
        "lib",
        f"python{sys.version_info.major}.{sys.version_info.minor}",
        "site-packages",
    )
    sys.path.insert(0, site_packages_path)
    return venv_path


def create_venv(venv_path, requirements_file=None):
    """Create a virtual environment and optionally install dependencies."""
    if not os.path.exists(os.path.join(venv_path, "bin", "pip")):
        subprocess.run([sys.executable, "-m", "venv", venv_path], check=True)
        pip_executable = os.path.join(venv_path, "bin", "pip")
        subprocess.run([pip_executable, "install", "--upgrade", "pip"], check=True)
        if requirements_file and os.path.exists(requirements_file):
            with open(requirements_file, "r") as f:
                list_requirements = "\n".join(
                    [
                        f"📦 {line.strip()}"
                        for line in f
                        if line.strip() and not line.startswith("#")
                    ]
                )
            notify.send(
                "HyDE PIP",
                f"⏳Install virtual environment Dependencies:\n {list_requirements}",
            )
            result = subprocess.run(
                [pip_executable, "install", "-r", requirements_file],
                capture_output=True,
                text=True,
            )
            result.check_returncode()
        notify.send("HyDE PIP", "✅ Virtual environment created successfully")
    else:
        pass


def destroy_venv(venv_path):
    """Destroy the virtual environment while retaining the requirements.txt file."""
    if os.path.exists(venv_path):
        shutil.rmtree(venv_path)
    pass


def install_dependencies(venv_path, requirements_file=None):
    """Install dependencies in the virtual environment."""
    if not os.path.exists(venv_path):
        create_venv(venv_path, requirements_file)
    else:
        pip_executable = os.path.join(venv_path, "bin", "pip")
        command = [pip_executable, "install", "-r", requirements_file]
        result = subprocess.run(command, capture_output=True, text=True)
        result.check_returncode()


def install_package(venv_path, package):
    """Install a single package in the virtual environment."""
    if not os.path.exists(venv_path):
        create_venv(venv_path)
    pip_executable = os.path.join(venv_path, "bin", "pip")
    command = [pip_executable, "install", package]
    result = subprocess.run(command, capture_output=True, text=True)
    result.check_returncode()


def uninstall(venv_path, package):
    """Uninstall a single package from the virtual environment."""
    pip_executable = os.path.join(venv_path, "bin", "pip")
    command = [pip_executable, "uninstall", "-y", package]
    result = subprocess.run(command, capture_output=True, text=True)
    result.check_returncode()


def rebuild_venv(venv_path, requirements_file=None):
    """Rebuild the virtual environment: reinstall if missing, install/upgrade requirements, and update all packages."""
    pip_executable = os.path.join(venv_path, "bin", "pip")
    if not os.path.exists(pip_executable):
        create_venv(venv_path, requirements_file)
    # 更新 pip
    subprocess.run([pip_executable, "install", "--upgrade", "pip"], check=True)
    # 更新包
    if requirements_file and os.path.exists(requirements_file):
        command = [pip_executable, "install", "--upgrade", "-r", requirements_file]
        subprocess.run(command, check=True)
    # 更新过时包
    command = [pip_executable, "list", "--outdated", "--format=freeze"]
    result = subprocess.run(command, capture_output=True, text=True)
    outdated = [line.split("==")[0] for line in result.stdout.splitlines() if line]
    if outdated:
        subprocess.run(
            [pip_executable, "install", "--upgrade", "-q"] + outdated, check=True
        )
    notify.send("HyDE PIP", "✅ Virtual environment rebuilt and packages updated.")


def v_import(module_name):
    """Dynamically import a module, installing it if necessary."""
    venv_path = get_venv_path()
    sys.path.insert(0, venv_path)  # Ensure sys.path is updated before import
    try:
        module = importlib.import_module(module_name)
        return module
    except ImportError:
        notify.send("HyDE PIP", f"Installing {module_name} module...")
        install_package(venv_path, module_name)

        # Reload sys.path to include the new module
        importlib.invalidate_caches()
        sys.path.insert(0, venv_path)
        sys.path.insert(
            0,
            os.path.join(
                venv_path,
                "lib",
                f"python{sys.version_info.major}.{sys.version_info.minor}",
                "site-packages",
            ),
        )

        try:
            module = importlib.import_module(module_name)
            notify.send("HyDE PIP", f"Successfully installed {module_name}.")
            return module
        except ImportError as e:
            notify.send(
                "HyDE Error",
                f"Failed to import module {module_name} after installation: {e}",
                urgency="critical",
            )
            raise


def main(args):
    parser = argparse.ArgumentParser(description="Python environment manager for Hyde")
    subparsers = parser.add_subparsers(dest="command")

    create_parser = subparsers.add_parser(
        "create", help="Create the virtual environment"
    )
    create_parser.set_defaults(func=create_venv)

    install_parser = subparsers.add_parser(
        "install", help="Install dependencies or a single package"
    )
    install_parser.add_argument("packages", nargs="*", help="Packages to install")
    install_parser.add_argument(
        "-f",
        "--requirements",
        type=str,
        help="The requirements file to use for installation",
    )
    install_parser.set_defaults(func=install_dependencies)

    uinstall_parser = subparsers.add_parser(
        "uninstall", help="Uninstall a single package"
    )
    uinstall_parser.add_argument("package", help="Package to uninstall")

    destroy_parser = subparsers.add_parser(
        "destory", help="Destroy the virtual environment"
    )
    destroy_parser.set_defaults(func=destroy_venv)

    rebuild_parser = subparsers.add_parser(
        "rebuild", help="Rebuild the virtual enviroment and update packages"
    )
    rebuild_parser.set_defaults(func=rebuild_venv)

    args = parser.parse_args(args)
    venv_path = get_venv_path()
    requirements_file = os.path.join(
        os.path.expanduser("~/.config/hypr/scripts/pyutils"), "requirements.txt"
    )

    if args.command == "create":
        args.func(venv_path, requirements_file)
    elif args.command == "install":
        if args.packages:
            for package in args.packages:
                install_package(venv_path, package)
        else:
            args.func(venv_path, args.requirements or requirements_file)
    elif args.command == "uninstall":
        args.func(venv_path, args.package)
    elif args.command == "destory":
        args.func(venv_path)
    elif args.command == "rebuild":
        args.func(venv_path, requirements_file)
    else:
        parser.print_help()


if __name__ == "__main__":
    main(sys.argv[1:])

# 将创建的环境设置为优先查找路径
sys.path.insert(0, get_venv_path())
