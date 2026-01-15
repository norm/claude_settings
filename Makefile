test:
	flake8
	bats tests/

install: test
	python merge-settings.py
