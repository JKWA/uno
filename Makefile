
setup:
	mix deps.get

start: 
	mix phx.server

lint:
	@echo "Linting code..."
	@echo "Running Dializer..."
	MIX_ENV=dev mix dialyzer
	@echo "Running Credo..."
	MIX_ENV=dev mix credo --strict

coverage:	
	@echo "Running tests..."
	MIX_ENV=dev mix format
	MIX_ENV=test mix coveralls.html