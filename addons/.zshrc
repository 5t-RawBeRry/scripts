# Antigen: https://github.com/zsh-users/antigen
ANTIGEN="$HOME/.local/bin/antigen.zsh"

# Install antigen.zsh if not exist
if [ ! -f "$ANTIGEN" ]; then
  echo "Installing antigen ... please connect the proxy"
  #export all_proxy=socks5://127.0.0.1:1086
  [ ! -d "$HOME/.local" ] && mkdir -p "$HOME/.local" 2> /dev/null
  [ ! -d "$HOME/.local/bin" ] && mkdir -p "$HOME/.local/bin" 2> /dev/null
  [ ! -f "$HOME/.z" ] && touch "$HOME/.z"
  URL="http://git.io/antigen"
  TMPFILE="/tmp/antigen.zsh"
  if [ -x "$(which curl)" ]; then
    curl -L "$URL" -o "$TMPFILE"
  elif [ -x "$(which wget)" ]; then
    wget "$URL" -O "$TMPFILE"
  else
    echo "ERROR: please install curl or wget before installation !!"
    exit
  fi
  if [ ! $? -eq 0 ]; then
    echo ""
    echo "ERROR: downloading antigen.zsh ($URL) failed !!"
    exit
  fi;
  echo "move $TMPFILE to $ANTIGEN"
  mv "$TMPFILE" "$ANTIGEN"
fi

# alias begin
alias c='clear'
alias e='exit'
alias q='exit'
# alias python='python3'
# alias end

VISUAL=nano; export VISUAL EDITOR=nano; export EDITOR

# fzf
export FZF_DEFAULT_OPTS='--bind ctrl-e:down,ctrl-u:up --preview "[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || (ccat --color=always {} || highlight -O ansi -l {} || cat {}) 2> /dev/null | head -500"'
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git --ignore-dir=node_modules -g ""'
export FZF_COMPLETION_TRIGGER='\'
export FZF_TMUX_HEIGHT='80%'
export FZF_PREVIEW_COMMAND='[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || (ccat --color=always {} || highlight -O ansi -l {} || cat {}) 2> /dev/null | head -500'


export LSCOLORS=exfxcxdxbxexexxxxxxxxx
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

#eval $(thefuck --alias)
# You can use whatever you want as an alias, like for Mondays:
#eval $(thefuck --alias FUCK)

PATH=$PATH:~/.local/bin

# Initialize command prompt
#export PS1="%n@%m:%~%# "

# Enable 256 color to make auto-suggestions look nice
export TERM="xterm-256color"


# Load local bash/zsh compatible settings
_INIT_SH_NOFUN=1
#[ -f "$HOME/.local/etc/init.sh" ] && source "$HOME/.local/etc/init.sh"

# exit for non-interactive shell
#[[ $- != *i* ]] && return

# WSL (aka Bash for Windows) doesn't work well with BG_NICE
#[ -d "/mnt/c" ] && [[ "$(uname -a)" == *Microsoft* ]] && unsetopt BG_NICE

# Initialize antigen
source "$ANTIGEN"


# Initialize oh-my-zsh
antigen use oh-my-zsh

# default bundles
# visit https://github.com/unixorn/awesome-zsh-plugins
antigen bundle pip
antigen bundle svn-fast-info

antigen bundle colorize
antigen bundle github
antigen bundle python
antigen bundle rupa/z z.sh
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle sobolevn/wakatime-zsh-plugin

antigen bundle willghatch/zsh-cdr

antigen theme xxf
#syntax color definition
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

typeset -A ZSH_HIGHLIGHT_STYLES

#ZSH_HIGHLIGHT_STYLES[command]=fg=white,bold
#ZSH_HIGHLIGHT_STYLES[alias]='fg=magenta,bold'

ZSH_HIGHLIGHT_STYLES[default]=none
ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=009
ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=009,standout
ZSH_HIGHLIGHT_STYLES[alias]=fg=cyan,bold
ZSH_HIGHLIGHT_STYLES[builtin]=fg=cyan,bold
ZSH_HIGHLIGHT_STYLES[function]=fg=cyan,bold
ZSH_HIGHLIGHT_STYLES[command]=fg=white,bold
ZSH_HIGHLIGHT_STYLES[precommand]=fg=white,underline
ZSH_HIGHLIGHT_STYLES[commandseparator]=none
ZSH_HIGHLIGHT_STYLES[hashed-command]=fg=009
ZSH_HIGHLIGHT_STYLES[path]=fg=214,underline
ZSH_HIGHLIGHT_STYLES[globbing]=fg=063
ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=white,underline
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=none
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=none
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=063
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=063
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=009
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=009
ZSH_HIGHLIGHT_STYLES[assign]=none

# load local config
[ -f "$HOME/.local/etc/config.zsh" ] && source "$HOME/.local/etc/config.zsh"
[ -f "$HOME/.local/etc/local.zsh" ] && source "$HOME/.local/etc/local.zsh"
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

antigen apply


# default keymap
bindkey -s '\ee' 'nvim\n'
bindkey '\eh' backward-char
bindkey '\el' forward-char
bindkey '\ej' down-line-or-history
bindkey '\ek' up-line-or-history
# bindkey '\eu' undo
bindkey '\eH' backward-word
bindkey '\eL' forward-word
bindkey '\e[H' beginning-of-line
bindkey '\e[F' end-of-line

bindkey -s '\eo' 'cd ..\n'
bindkey -s '\e;' 'll\n'

bindkey '\e[1;3D' backward-word
bindkey '\e[1;3C' forward-word
bindkey '\e[1;3A' beginning-of-line
bindkey '\e[1;3B' end-of-line

alias ll='ls -l'


# options
unsetopt correct_all

setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY # Don't execute immediately upon history expansion.


# source function.sh if it exists
[ -f "$HOME/.local/etc/function.sh" ] && . "$HOME/.local/etc/function.sh"


# ignore complition
zstyle ':completion:*:complete:-command-:*:*' ignored-patterns '*.pdf|*.exe|*.dll'
zstyle ':completion:*:*sh:*:' tag-order files

setopt nonomatch

# Use beam shape cursor on startup.
echo -ne '\e[5 q'

# Use beam shape cursor for each new prompt.
preexec() {
  echo -ne '\e[5 q'
}

_fix_cursor() {
  echo -ne '\e[5 q'
}
precmd_functions+=(_fix_cursor)

# Copy and self modified from ys.zsh-theme, the one of default themes in master repository
# Clean, simple, compatible and meaningful.
# Tested on Linux, Unix and Windows under ANSI colors.
# It is recommended to use with a dark background and the font Inconsolata.
# Colors: black, red, green, yellow, *blue, magenta, cyan, and white.
#
# http://xiaofan.at
# 2 Jul 2015 - Xiaofan

# Machine name.
function box_name {
    [ -f ~/.box-name ] && cat ~/.box-name || echo $HOST
}

# Directory info.
local current_dir='${PWD/#$HOME/~}'

# VCS
YS_VCS_PROMPT_PREFIX1="%{$fg[white]%}on%{$reset_color%} "
YS_VCS_PROMPT_PREFIX2=":%{$fg[cyan]%}"
YS_VCS_PROMPT_SUFFIX="%{$reset_color%} "
YS_VCS_PROMPT_DIRTY=" %{$fg[red]%}✗"
YS_VCS_PROMPT_CLEAN=" %{$fg[green]%}✔︎"

# Git info.
local git_info='$(git_prompt_info)'
local git_last_commit='$(git log --pretty=format:"%h \"%s\"" -1 2> /dev/null)'
ZSH_THEME_GIT_PROMPT_PREFIX="${YS_VCS_PROMPT_PREFIX1}git${YS_VCS_PROMPT_PREFIX2}"
ZSH_THEME_GIT_PROMPT_SUFFIX="$YS_VCS_PROMPT_SUFFIX"
ZSH_THEME_GIT_PROMPT_DIRTY="$YS_VCS_PROMPT_DIRTY"
ZSH_THEME_GIT_PROMPT_CLEAN="$YS_VCS_PROMPT_CLEAN"

# HG info
local hg_info='$(ys_hg_prompt_info)'
ys_hg_prompt_info() {
	# make sure this is a hg dir
	if [ -d '.hg' ]; then
		echo -n "${YS_VCS_PROMPT_PREFIX1}hg${YS_VCS_PROMPT_PREFIX2}"
		echo -n $(hg branch 2>/dev/null)
		if [ -n "$(hg status 2>/dev/null)" ]; then
			echo -n "$YS_VCS_PROMPT_DIRTY"
		else
			echo -n "$YS_VCS_PROMPT_CLEAN"
		fi
		echo -n "$YS_VCS_PROMPT_SUFFIX"
	fi
}

# Prompt format: \n # TIME USER at MACHINE in [DIRECTORY] on git:BRANCH STATE \n $ 
PROMPT="
%{$fg[cyan]%}%n \
%{$fg[white]%}at \
%{$fg[green]%}$(box_name) \
%{$fg[white]%}in \
%{$terminfo[bold]$fg[yellow]%}[${current_dir}]%{$reset_color%} \
${hg_info} \
${git_info} \
${git_last_commit}
%{$fg[red]%}%* \
%{$terminfo[bold]$fg[white]%}› %{$reset_color%}"

if [[ "$USER" == "root" ]]; then
PROMPT="
%{$fg[red]%}%* \
%{$terminfo[bold]$fg[blue]%}#%{$reset_color%} \
%{$bg[yellow]%}%{$fg[cyan]%}%n%{$reset_color%} \
%{$fg[white]%}at \
%{$fg[green]%}$(box_name) \
%{$fg[white]%}in \
%{$terminfo[bold]$fg[yellow]%}[${current_dir}]%{$reset_color%}\
${hg_info}\
${git_info}
%{$terminfo[bold]$fg[red]%}$ %{$reset_color%}"
fi

export ZSH_WAKATIME_BIN=~/.local/bin/wakatime

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
