main:
	@swift build
	@cp .build/debug/BraveCmd brave
	@chmod +x brave
	@echo "Run the program with ./brave"
