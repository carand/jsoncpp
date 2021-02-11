CMAKE = cmake
#Switch to activatad Build Type
BUILD_TYPE=Release
# BUILD_TYPE=Release
# BUILD_TYPE=RelWithDebInfo
# BUILD_TYPE=MinSizeRel

DEFAULT_RUN_ARGS= " -vf"
CURDIR=$(shell pwd)
RELEASE_DIR=$(CURDIR)/INSTALL_DIR

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
	-DCMAKE_CXX_FLAGS=-m32 \
	-DBUILD_32=ON



CMAKE_RELEASE_OPTIONS :=  \
	-DCMAKE_CXX_FLAGS=-m32 \
	-DBUILD_32=ON

release:
	$(CMAKE) -H. -BRelease -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles"  \
	-DCMAKE_CXX_FLAGS=-m32 \
	-DCMAKE_INSTALL_PREFIX:PATH=$(RELEASE_DIR)
	$(MAKE) -C Release all


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
clean: clean_spell
	$(RM) -fr tags
	$(RM) -fr cscope.out
	test -d $(CMAKE_BUILD_DIR) && $(MAKE) -sC $(CMAKE_BUILD_DIR) clean $(ARGS); cd ..
	# $(MAKE) -C $(CMAKE_BUILD_DIR) clean

$(APP_TEST): | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR) $(APP_TEST)

utest: $(APP_TEST) | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR) test

build: generate_build_tool
	# $(CMAKE) --build $(CMAKE_BUILD_DIR)
	# $(MAKE) all


cppcheck:
	cppcheck --project=build/compile_commands.json --enable=all

# cppcheck: | $(compile_comands)
	# cd $(CMAKE_BUILD_DIR) && cppcheck --project=compile_commands.json; cd ..


compile_commands: $(compile_comands)

$(compile_commands): $(APP_NAME) | $(CMAKE_BUILD_DIR)
	$(MAKE) -C $(CMAKE_BUILD_DIR) $(APP_NAME)


install_package: | $(APP_NAME)
	mkdir -p $(RELEASE_DIR)
	cd $(CMAKE_BUILD_DIR) && $(MAKE) package &&  cp *.deb $(RELEASE_DIR) && cd ..
	cd $(CMAKE_BUILD_DIR) && $(MAKE) package_source &&  cp *-Source.tar.gz $(RELEASE_DIR) && cd ..

install_release: distclean release
	mkdir -p $(RELEASE_DIR)
	cd Release && $(MAKE) install && cd ..

install_global:|
	$(MAKE) $(APP_NAME)
	cd ${CMAKE_BUILD_DIR} && sudo $(MAKE) install && cd ..


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
	python2 $(SPELLGEN) -o ~/.vim/spell --clear $(SPELLFILE)

pack:
	@($(MAKE) -C $(CMAKE_BUILD_DIR) package)

rtags: compile_commands
	rc -J $(compile_commands)


.PHONY: distclean
distclean:  clean
	$(RM) -fr $(RELEASE_DIR)
	$(RM) -fr $(CMAKE_BUILD_DIR)
	$(RM) -fr Release
	$(RM) -fr Debug
	$(RM) -fr CodeblocksDebug
	$(RM) -fr CodeblocksRelease
	$(RM) -f tags
	$(RM) -f cscope.out
	$(RM) -f cscope.out.*
	$(RM) -f *.orig
	$(RM) -f ncscope.out.*

