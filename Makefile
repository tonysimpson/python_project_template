ENV_DIR = $(CURDIR)/.venv
ENV = $(ENV_DIR)/.venv
ENV_RUN_DEP = $(ENV_DIR)/.run-dep
ENV_TEST_DEP = $(ENV_DIR)/.test-dep
PYTHON3 = $(ENV_DIR)/bin/python3
PIP = $(PYTHON3) -m pip
TEST_DIR = tests

.PHONY: test
test: venv-test $(DEV_CONFIG) start-db
	$(PYTHON3) -m pytest $(TEST_DIR) $(PYTEST_ARGS)
	$(MAKE) lint

.PHONY: clean-coverage
clean-coverage:
	rm -fr .coverage
	rm -fr htmlcov

.PHONY: coverage
coverage: venv-test $(DEV_CONFIG) start-db clean-coverage
	$(PYTHON3) -m coverage run --omit="$(TEST_DIR)/*" --source=. -m pytest $(TEST_DIR) $(PYTEST_ARGS)
	$(PYTHON3) -m coverage report
	$(PYTHON3) -m coverage html
	$(PYTHON3) -m webbrowser htmlcov/index.html

.PHONY: flake8
flake8: venv-test
# Ignore errors that conflict with black
	$(PYTHON3) -m flake8 --ignore=E203,W503 --exclude $(ENV_DIR)

.PHONY: black-check
black-check: venv-test
	$(PYTHON3) -m black --check --exclude $(ENV_DIR) .

.PHONY: black
black: venv-test
	$(PYTHON3) -m black --exclude $(ENV_DIR) .

.PHONY: shellcheck
shellcheck:
	shellcheck -e SC1090 -e SC1091 -x scripts/*.sh

.PHONY: lint
lint: black-check flake8 shellcheck

.PHONY: notebook
notebook: venv
	$(PYTHON3) -m jupyter notebook --notebook-dir=notebooks

.PHONY: venv
venv: $(ENV_RUN_DEP)

.PHONY: venv-test
venv-test: $(ENV_TEST_DEP)

$(ENV):
	rm -fr "$(ENV_DIR)"
	python3.8 -m venv "$(ENV_DIR)"
	touch $(ENV)

$(ENV_RUN_DEP): $(ENV) requirements.txt
	$(PIP) install --no-warn-script-location --upgrade pip
	$(PIP) install --no-warn-script-location wheel
	$(PIP) install --no-warn-script-location -r requirements.txt
	touch $(ENV_RUN_DEP)

$(ENV_TEST_DEP): $(ENV_RUN_DEP) requirements-test.txt
	$(PIP) install --no-warn-script-location -r requirements-test.txt
	touch $(ENV_TEST_DEP)

.PHONY: clean
clean: clean-db clean-coverage
	rm -fr $(ENV_DIR)
	find -name '*.pyc' -type f -delete
	find -name '__pycache__' -type d -delete

.DELETE_ON_ERROR:
