import argparse
from pathlib import Path
import os, sys
import subprocess
import urllib.request
import shutil
import tarfile

ROOT=os.path.dirname(os.path.dirname(os.path.dirname(__file__)))


# List of dependencies to build from source
DEPENDENCIES = [
    {
        "name": "PugiXML",
        "url": "https://github.com/zeux/pugixml.git",
        "tag": "v1.10",
        "options": []
    },
    {
        "name": "openjpeg",
        "url": "https://github.com/uclouvain/openjpeg.git",
        "tag": "v2.5.0",
        "options": ["-DBUILD_THIRDPARTY:BOOL=ON", "-DBUILD_TESTING:BOOL=OFF", "-DBUILD_TOOLS:BOOL=OFF"]
    },
]

def build_dependency(dep, install_dir):
    # We store source and temporary build files in a 'build' subfolder
    
    work_dir = Path(os.path.dirname(ROOT)) / "build_temp"
    repo_dir = work_dir / "src" / dep["name"]
    build_dir = work_dir / "build" / dep["name"]

    src_dir = repo_dir / dep.get("relative_path", "")

    # 1. Clone/Fetch
    if dep.get("uses_lfs", False):
        if not repo_dir.exists():
            print(f"--- Cloning {dep['name']} ---")
            # For LLVM, we recommend --depth 1 because the repo is massive (>1GB)
            subprocess.run([
                "git", "clone", "--branch", dep["tag"], 
                "--recursive", dep["url"], str(repo_dir)
            ], check=True)
    else:
        if not repo_dir.exists():
            print(f"--- Cloning {dep['name']} ---")
            # For LLVM, we recommend --depth 1 because the repo is massive (>1GB)
            subprocess.run([
                "git", "clone", "--branch", dep["tag"], 
                "--depth", "1", dep["url"], str(repo_dir)
            ], check=True)

    # 2. Configure with CMake
    build_dir.mkdir(parents=True, exist_ok=True)
    cmake_cmd = [
        "cmake",
        "-S", str(src_dir),
        "-B", str(build_dir),
        f"-DCMAKE_INSTALL_PREFIX={install_dir}",
        f"-DCMAKE_PREFIX_PATH={install_dir}",
        "-DBUILD_SHARED_LIBS=ON",
        "-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
        "-DCMAKE_CXX_STANDARD=17",
        "-DCMAKE_CXX_STANDARD_REQUIRED=ON",
        *dep.get("options", [])
    ]
    
    print(f"\n--- Configuring {dep['name']} ---")
    subprocess.run(cmake_cmd, check=True)

    # 3. Build & Install to the houdini/lib path
    print(f"\n--- Building {dep['name']} ---")
    subprocess.run([
        "cmake", 
        "--build", str(build_dir), 
        "--target", "install", 
        "--config", "Release",
        "--parallel 14" # Uses all available CPU cores
    ], check=True)

def install_epoxy(install_root):
    import subprocess, shutil
    from pathlib import Path

    epoxy_git = "https://github.com/anholt/libepoxy.git"
    epoxy_tag = "1.5.10"

    install_root = Path(install_root)
    temp_dir = Path("./temp_epoxy")
    repo_dir = temp_dir / "libepoxy"
    build_dir = repo_dir / "build"

    print(f"--- Installing Epoxy ---")

    temp_dir.mkdir(parents=True, exist_ok=True)

    # Clone if not exists
    if not repo_dir.exists():
        print("--- Cloning Epoxy ---")
        subprocess.run([
            "git", "clone",
            "--branch", epoxy_tag,
            "--depth", "1",
            epoxy_git,
            str(repo_dir)
        ], check=True)

    # Ensure Meson build dir is clean
    if build_dir.exists():
        shutil.rmtree(build_dir)

    # 1. Setup Meson build
    subprocess.run([
        "meson", "setup", str(build_dir),
        "--prefix", str(install_root),
        "--buildtype=release"
    ], cwd=repo_dir, check=True)

    # 2. Compile
    subprocess.run([
        "meson", "compile", "-C", str(build_dir)
    ], cwd=repo_dir, check=True)

    # 3. Install
    subprocess.run([
        "meson", "install", "-C", str(build_dir)
    ], cwd=repo_dir, check=True)

    # 4. Cleanup
    shutil.rmtree(temp_dir)
    print("--- Epoxy installed successfully ---")

def parse_args():
    parser = argparse.ArgumentParser(description="Build Houdini dependency stack")

    parser.add_argument(
        "--hfs",
        required=True,
        help="Path to Houdini installation (e.g. /opt/hfs21.0)"
    )

    return parser.parse_args()

def main():
    args = parse_args()

    HFS = os.path.abspath(args.hfs)

    print(f"Using Houdini: {HFS}")
    
    # Define the final installation path: houdini_root/lib/houdini
    install_path = os.path.join(ROOT, "lib", "houdini")
    os.makedirs(install_path, exist_ok=True)

    print(f"Install Path: {install_path}")

    install_epoxy(install_path)

    for dep in DEPENDENCIES:
        try:
            build_dependency(dep, install_path)
        except subprocess.CalledProcessError as e:
            print(f"\n[!] Failed to build {dep['name']}: {e}")
            return

    print(f"\nSuccess! All dependencies installed to: {install_path}")

if __name__ == "__main__":
    main()