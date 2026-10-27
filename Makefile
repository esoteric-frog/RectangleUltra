CLT := /Library/Developer/CommandLineTools/Library/Developer
# Command Line Tools only: point swift test at swift-testing. With Xcode selected (CI) it finds it alone.
ifeq ($(shell xcode-select -p),/Library/Developer/CommandLineTools)
TESTFLAGS := -Xswiftc -F$(CLT)/Frameworks -Xlinker -F$(CLT)/Frameworks \
             -Xlinker -rpath -Xlinker $(CLT)/Frameworks -Xlinker -rpath -Xlinker $(CLT)/usr/lib
endif

.PHONY: app debug install test clean
app:
	scripts/bundle.sh release
debug:
	scripts/bundle.sh debug
install: app
	osascript -e 'quit app "Rectangle Ultra"' 2>/dev/null || true
	rm -rf "/Applications/Rectangle Ultra.app"
	ditto "build/Rectangle Ultra.app" "/Applications/Rectangle Ultra.app"
	@echo "installed /Applications/Rectangle Ultra.app"
test:
	python3 scripts/gen_xctest_wrappers.py
	swift test --no-parallel $(TESTFLAGS)
clean:
	rm -rf .build build
