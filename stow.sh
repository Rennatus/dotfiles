local packages=("zsh" "nvim")

for package in "${packages[@]}"; do
  safe_stow "$package"
done