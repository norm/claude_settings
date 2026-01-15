test:
	flake8
	bats tests/

install:
	python merge-settings.py
