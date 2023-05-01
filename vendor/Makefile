CFG=git --git-dir=${HOME}/.dotfiles/ --work-tree=${HOME}
VENDOR=${HOME}/vendor

.PHONY: update
update:
	${CFG} submodule update --remote

.PHONY: nvim
nvim:
	${CFG} submodule update --remote ${VENDOR}/neovim/
	cd ${VENDOR}/neovim; make CMAKE_BUILD_TYPE=Release; sudo make install

.PHONY: awesome
awesome:
	${CFG} submodule update --remote ${VENDOR}/awesome/
	cd ${VENDOR}/awesome; make; sudo make install

.PHONY: wezterm
wezterm:
	${CFG} submodule update --remote ${VENDOR}/wezterm/
	cd ${VENDOR}/wezterm; cargo install --path=./

.PHONY: all
all: nvim awesome
	@echo "Done!"
