.PHONY: chmod-scripts

chmod-scripts:
	find scripts/ -type f -name "*.sh" -exec chmod +x {} \;