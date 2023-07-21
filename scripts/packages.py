import os

class PackageManager: # Abstract class
    def setup(self):
        pass

    def install(self, package):
        pass

    def uninstall(self, package):
        pass

class Cargo(PackageManager):
    def __init__(self):
        self.name = "Cargo"
        self.installed = True if os.system("cargo --version") == 0 else False

    def setup(self):
        if not self.installed:
            print("Installing Cargo...")
            os.system("curl https://sh.rustup.rs -sSf | sh")
            self.installed = True
        else:
            print("Cargo already installed")

    def install(package):
        os.system(f"cargo install {package}")

    def uninstall(package):
        os.system(f"cargo uninstall {package}")

    def update(package):
        if package:
            os.system(f"cargo install-update {package}")
        else:
            os.system("cargo update")

class Pacman(PackageManager):
    def __init__(self):
        self.name = "Pacman"
        self.installed = True if os.system("pacman --version") == 0 else False

    def setup(self):
        if not self.installed:
            print("This script is only intended for Arch Linux")
    
    def install(package):
        os.system(f"pacman -Sy {package}")
