#!/usr/bin/env fish

set -l os (uname -s)

echo "Bootstrapping Catie's Emacs environment..."

switch $os
    case Darwin
        echo "Detected macOS"

        if not type -q brew
            echo "Homebrew is required first."
            exit 1
        end

        set packages \
            emacs \
            ripgrep \
            cmake \
            libvterm \
            lazygit

        for package in $packages
            if brew list $package >/dev/null 2>&1
                echo "✓ $package"
            else
                echo "Installing $package..."
                brew install $package
            end
        end

    case Linux
        echo "Detected Linux"

        if type -q emerge
            echo "Detected Gentoo"

            echo
            echo "Install the Gentoo system dependencies with:"
            echo
            echo "  sudo emerge \\"
            echo "      app-editors/emacs \\"
            echo "      sys-apps/ripgrep \\"
            echo "      dev-build/cmake \\"
            echo "      dev-libs/libvterm"
            echo
            echo "LazyGit may come from your preferred Gentoo source/overlay."
            echo
            echo "Not automatically emerging packages because USE flags"
            echo "should remain under your control."

        else
            echo "Unsupported Linux package manager."
            echo "Install Emacs, ripgrep, cmake, libvterm, and lazygit manually."
        end

    case '*'
        echo "Unsupported OS: $os"
        exit 1
end

echo
echo "Checking tools..."

for command in emacs rg cmake lazygit
    if type -q $command
        echo "✓ $command"
    else
        echo "✗ $command missing"
    end
end

echo
echo "Bootstrap complete."
echo "Start Emacs once to install Emacs packages."
