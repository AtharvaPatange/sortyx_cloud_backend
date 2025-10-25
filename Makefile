.PHONY: help install run docker-build docker-run test clean

help:
	@echo "Sortyx CloudApp - Available commands:"
	@echo "  make install       - Install dependencies"
	@echo "  make run          - Run the application"
	@echo "  make docker-build - Build Docker image"
	@echo "  make docker-run   - Run Docker container"
	@echo "  make docker-up    - Start with docker-compose"
	@echo "  make docker-down  - Stop docker-compose"
	@echo "  make test         - Run tests"
	@echo "  make clean        - Clean temporary files"
	@echo "  make logs         - View application logs"

install:
	pip install -r requirements.txt

run:
	python app.py

dev:
	uvicorn app:app --host 0.0.0.0 --port 8000 --reload

docker-build:
	docker build -t sortyx-cloudapp:latest .

docker-run:
	docker run -d -p 8000:8000 --env-file .env --name sortyx-cloudapp sortyx-cloudapp:latest

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f

test:
	@echo "Running basic import test..."
	python -c "from app import app; print('✅ App imports successfully')"
	@echo "Testing health endpoint..."
	@curl -f http://localhost:8000/health || echo "⚠️ Server not running"

clean:
	find . -type f -name '*.pyc' -delete
	find . -type d -name '__pycache__' -delete
	find . -type f -name '*.log' -delete
	rm -rf build/ dist/ *.egg-info
	@echo "✅ Cleaned temporary files"

logs:
	tail -f *.log 2>/dev/null || echo "No log files found"

health:
	@echo "Checking application health..."
	@curl -s http://localhost:8000/health | python -m json.tool || echo "❌ Server not responding"

stop:
	@docker stop sortyx-cloudapp 2>/dev/null || echo "Container not running"
	@docker rm sortyx-cloudapp 2>/dev/null || echo "Container already removed"
