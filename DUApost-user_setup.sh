#!/bin/bash

nl=$'\n==========\n'
src=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
exec 1> >(tee -a "$src"/post_user.log)
exec 2> >(tee -a "$src"/post_err_user.log)

echo -e "${nl}SETTING UP USER TWEAKS${nl}"

nvidia_chk(){
    [[ $(lshw -quiet -C display | grep vendor | cut -d\: -f2) = "NVIDIA Corporation" ]] \
        && nvidia=1 \
        || nvidia=0
}
dot_ins() {
    echo -e "${nl}installing dotfiles${nl}"
    while read stowdir; do
        stow -d "$HOME"/grepo/dotfiles -t "$HOME" "$stowdir"
    done < "$src"/pkg-stow
}
pyruby_ins() {
    cd "$HOME"
    echo -e "${nl}installing ruby gems${nl}"
    gem install --user-install tmuxinator github-pages

    echo -e "${nl}installing pip packages${nl}"
    virtualenv -p python3 "$HOME"/.local/pyvenv
    source "$HOME"/.local/pyvenv/bin/activate
    pip3 install -r "$src"/pkg-pip
    deactivate
}
bin_ins() {
    echo -e "${nl}aggregating user binaries${nl}"
    local dirs=""$HOME"/grepo/bin "$HOME"/.local/pyvenv/bin "$HOME"/.gem/ruby/2.3.0/bin"
    find $dirs \
        -follow \
        -mindepth 1 \
        -maxdepth 1 \
        -type f \
        -executable \
        -exec ln -s {} "$HOME"/.local/bin \;
}
systemd_user_ins() {
   [[ "$nvidia" = 1 ]] \
       && systemctl --user enable nvidia.timer \
       && systemctl --user start nvidia.service
   while read serv_user; do
       systemctl --user enable "$serv_user"
       systemctl --user start "$serv_user"
   done < "$src"/services-user
}

nvidia_chk
dot_ins
pyruby_ins
bin_ins
systemd_user_ins

echo -e "${nl}USER SETUP FINISHED${nl}"
