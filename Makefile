.PHONY: install lint format test run build

install:
	uv sync --all-groups

lint:
	uv run ruff check .
	uv run ruff format --check .

format:
	uv run ruff format .
	uv run ruff check --fix .

test:
	uv run pytest $(ARGS)

run:
	uv run python -m mcp_play

build:
	docker build -t mcp-play .

docker-run:
	docker run --env-file .env mcp-play
