CMAKE = cmake
#Switch to activatad Build Type
BUILD_TYPE=Release
# BUILD_TYPE=Release
# BUILD_TYPE=RelWithDebInfo
# BUILD_TYPE=MinSizeRel

DEFAULT_RUN_ARGS= " -vf"
RELEASE_DIR=./INSTALL_DIR

DAFUR_DIR=/dafur
SRC_DIR=./src
INC_DIR=./include
CMAKE_BUILD_DIR= build
BROWSER=sensible-browser
HTML_INDEX_FILE=${CMAKE_BUILD_DIR}/doc/html/index.html
compile_commands=$(CMAKE_BUILD_DIR)/compile_commands.json

APP_NAME=jsoncpp
APP_TEST=unittests_$(APP_NAME)


MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR := $(dir $(MKFILE_PATH))
SPELLGEN=./support/generateSpellingListFromCTags.py
SPELLFILE=$(APP_NAME)FromTags
# TEST_APP_NAME=rfidTestApp
CMAKE_TEST_APP_DIR= $(CMAKE_BUILD_DIR)

# Switch to your prefered build tool.
BUILD_TOOL = "Unix Makefiles"
# BUILD_TOOL = "CodeBlocks - Unix Makefiles"
# BUILD_TOOL = "Eclipse CDT4 - Unix Makefiles"

# -DCMAKE_BUILD_TYPE=Debug -DCMAKE_ECLIPSE_GENERATE_SOURCE_PROJECT=TRUE -DCMAKE_ECLIPSE_MAKE_ARGUMENTS=-j3 -DCMAKE_ECLIPSE_VERSION=4.1

default: $(APP_NAME)

CMAKE_DEV_OPTIONS :=  \
	-DBUILD_32=ON



CMAKE_RELEASE_OPTIONS :=  \
	-DBUILD_32=ON

release:
	$(CMAKE) -H. -BRelease -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles"  \
	-DCMAKE_CXX_FLAGS=-m32 \
	-DCMAKE_INSTALL_PREFIX:PATH=$(RELEASE_DIR)
	$(MAKE) -C Release all


sanitize:
	$(CMAKE) -H. -B$(CMAKE_BUILD_DIR) -DCMAKE_BUILD_TYPE=Debug -G $(BUILD_TOOL) \
	$(CMAKE_DEV_OPTIONS) \
    -DCMAKE_CXX_FLAGS="-fsanitize=address  -fsanitize=leak -g" \
    -DCMAKE_C_FLAGS="-fsanitize=address  -fsanitize=leak -g" \
    -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address  -fsanitize=leak" \
	-DCMAKE_MODULE_LINKER_FLAGS="-fsanitize=address  -fsanitize=leak"
	$(MAKE) -C $(CMAKE_BUILD_DIR) $(APP_NAME)
debug:
	$(CMAKE) -H. -BRelease -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles"  \
	$(CMAKE_DEV_OPTIONS) \
	$(MAKE) -C build $(APP_NAME)


codeblocks_debug:
	$(CMAKE) -H. -BCodeblocksDebug -DCMAKE_BUILD_TYPE=Debug -G "CodeBlocks - Unix Makefiles"  \
	$(CMAKE_DEV_OPTIONS) \
	$(MAKE) -C CodeblocksDebug $(APP_NAME)
	$(MAKE) -C CodeblocksDebug doc


codeblocks_release:
	$(CMAKE) -H. -BCodeblocksRelease -DCMAKE_BUILD_TYPE=Release -G "CodeBlocks - Unix Makefiles"  \
	$(CMAKE_RELEASE_OPTIONS) \
	$(MAKE) -C CodeblocksRelease $(APP_NAME)
	$(MAKE) -C CodeblocksRelease doc

debug:
	$(CMAKE) -H. -BDebug -DCMAKE_BUILD_TYPE=Debug -G "Unix Makefiles"  \
	-DCMAKE_CXX_FLAGS=-m32 \
	$(MAKE) -C Debug $(APP_NAME)
	$(MAKE) -C Debug doc




$(CMAKE_BUILD_DIR): generate_build_tool


generate_build_tool:
	$(CMAKE) -H. -B$(CMAKE_BUILD_DIR) -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) -G $(BUILD_TOOL) \
	$(CMAKE_DEV_OPTIONS)


$(APP_NAME): | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR)
##
## @brief DocTest
##
##

.PHONY: clean
clean:
	$(RM) -r tags
	$(RM) -r cscope.out
	cd $(CMAKE_BUILD_DIR) &&  $(MAKE) clean $(ARGS); cd ..
	# $(MAKE) -C $(CMAKE_BUILD_DIR) clean

$(APP_TEST): | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR) $(APP_TEST)

utest: $(APP_TEST) | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR) test

build: generate_build_tool
	# $(CMAKE) --build $(CMAKE_BUILD_DIR)
	# $(MAKE) all

run: $(APP_NAME)
ifeq ($(ARGS),)
	$(MAKE) ARGS=$(DEFAULT_RUN_ARGS) run
else
	@( $(MAKE) -C  $(CMAKE_BUILD_DIR) link_target  )
	cd $(DAFUR_DIR) &&  ./$(APP_NAME) $(ARGS); cd ..
endif

gdb_run:
ifeq ($(ARGS),)
	$(MAKE) ARGS=$(DEFAULT_RUN_ARGS) gdb_run
else
	@( $(MAKE) -C  $(CMAKE_BUILD_DIR) link_target  )
	cd $(DAFUR_DIR) && tgdb --args $(APP_NAME) $(ARGS); cd ..
	# cd $(DAFUR_DIR) && gdb --args $(APP_NAME) $(ARGS); cd ..
endif

memcheck: $(APP_NAME)
ifeq ($(ARGS),)
	$(MAKE) ARGS=$(DEFAULT_RUN_ARGS) memcheck
else
	@( $(MAKE) -C  $(CMAKE_BUILD_DIR) link_target  )
	# cd $(DAFUR_DIR) && valgrind --leak-check=full  --track-origins=yes -v ./$(APP_NAME) $(ARGS); cd ..
	# cd $(DAFUR_DIR) && valgrind --leak-check=full -v ./$(APP_NAME) $(ARGS); cd ..
	cd $(DAFUR_DIR) && valgrind --leak-check=full --show-leak-kinds=all -v ./$(APP_NAME) $(ARGS); cd ..
endif

memcheck_test: $(APP_TEST)
	cd $(CMAKE_BUILD_DIR) &&  valgrind --leak-check=full -v ./$(APP_TEST); cd ..

cppcheck:
	cppcheck --project=build/compile_commands.json --enable=all

# cppcheck: | $(compile_comands)
	# cd $(CMAKE_BUILD_DIR) && cppcheck --project=compile_commands.json; cd ..


compile_commands: $(compile_comands)

$(compile_commands): $(APP_NAME) | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR) $(APP_NAME)


install_package: release
	mkdir -p $(RELEASE_DIR)
	cd Release && $(MAKE) package &&  cp *.deb $(RELEASE_DIR) && cd ..

install_release: release
	mkdir -p $(RELEASE_DIR)
	cd Release && $(MAKE) install && cd ..

install_global:|
	$(MAKE) $(APP_NAME)
	cd ${CMAKE_BUILD_DIR} && sudo $(MAKE) install && cd ..

install_release: distclean release
	mkdir -p $(RELEASE_DIR)
	cd Release && $(MAKE) install && cd ..

uninstall_global:|
	cd ${CMAKE_BUILD_DIR} && sudo $(MAKE) uninstall && cd ..

docs: | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR) doc

viewHtmlDoc: docs
	@($(BROWSER) $(HTML_INDEX_FILE))


coverage: | $(CMAKE_BUILD_DIR)
	@($(MAKE) -C $(CMAKE_BUILD_DIR) coverage && ${BROWSER} ${CMAKE_BUILD_DIR}/coverage/index.html)


tags: | $(CMAKE_BUILD_DIR)
	@($(MAKE) -C $(CMAKE_BUILD_DIR) tags)
	@( $(MAKE) rtags)

genspell: docs tags | $(CMAKE_BUILD_DIR)
	 python $(SPELLGEN) -o ~/.vim/spell -t tags -i $(CMAKE_BUILD_DIR)/doc/xml/index.xml $(SPELLFILE)

.PHONY: clean_spell
clean_spell:
	python $(SPELLGEN) -o ~/.vim/spell --clear $(SPELLFILE)

pack:
	@($(MAKE) -C $(CMAKE_BUILD_DIR) package)

rtags: compile_commands
	rc -J $(compile_commands)


.PHONY: distclean
distclean:  clean
	$(RM) -r $(CMAKE_BUILD_DIR)
	$(RM) -r Release
	$(RM) -r Debug
	$(RM) -r CodeblocksDebug
	$(RM) -r CodeblocksRelease
	$(RM) tags
	$(RM) cscope.out
	$(RM) cscope.out.*
	$(RM) *.orig
	$(RM) ncscope.out.*

