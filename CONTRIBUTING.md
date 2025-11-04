# Contributing to Instruktor

Thank you for your interest in contributing to Instruktor! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Code Style](#code-style)
- [Reporting Issues](#reporting-issues)

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/yourusername/instruktor.git
   cd instruktor
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/original/instruktor.git
   ```

## Development Setup

1. Install dependencies:
   ```bash
   ./instruktor setup
   # or
   make setup
   ```

2. Verify your setup:
   ```bash
   mix compile
   mix test
   ```

## Making Changes

1. Create a new branch for your feature or bug fix:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

2. Make your changes following the [Code Style](#code-style) guidelines

3. Add or update tests as necessary

4. Ensure all tests pass:
   ```bash
   mix test
   ```

5. Run code quality checks:
   ```bash
   mix credo --strict
   mix format --check-formatted
   ```

## Testing

- Write tests for new features and bug fixes
- Ensure all existing tests pass before submitting
- Tests should be placed in the `test/` directory
- Follow the existing test structure and naming conventions

Run tests with:
```bash
mix test
```

## Submitting Changes

1. Commit your changes with clear, descriptive commit messages:
   ```bash
   git commit -m "Add feature: brief description of what you added"
   # or
   git commit -m "Fix: brief description of what you fixed"
   ```

2. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

3. Create a Pull Request on GitHub:
   - Provide a clear description of the changes
   - Reference any related issues
   - Ensure all CI checks pass

## Code Style

### Elixir

- Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use `mix format` to format your code
- Run `mix credo` to check for style and consistency issues
- Add `@moduledoc` and `@doc` documentation for all public modules and functions
- Use `@spec` type annotations for all public functions

Example:
```elixir
defmodule MyModule do
  @moduledoc """
  Description of what this module does.
  """

  @doc """
  Description of what this function does.

  ## Parameters
    * `param1` - Description of parameter
    * `param2` - Description of parameter

  ## Returns
    * `{:ok, result}` - Success case
    * `{:error, reason}` - Error case
  """
  @spec my_function(String.t(), keyword()) :: {:ok, any()} | {:error, any()}
  def my_function(param1, param2 \\ []) do
    # Implementation
  end
end
```

### Python

- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- Use type hints for function signatures
- Add docstrings for all public functions and classes
- Use `black` for code formatting
- Use `pylint` or `flake8` for linting

Example:
```python
def my_function(param1: str, param2: Optional[int] = None) -> Dict[str, Any]:
    """
    Description of what this function does.

    Args:
        param1: Description of parameter
        param2: Description of parameter

    Returns:
        Dict containing the result
    """
    # Implementation
```

## Reporting Issues

When reporting issues, please include:

1. A clear, descriptive title
2. A detailed description of the issue
3. Steps to reproduce the problem
4. Expected behavior vs actual behavior
5. Your environment (OS, Elixir version, Python version, etc.)
6. Any relevant logs or error messages

## Questions?

If you have questions or need help, please:

- Open an issue for discussion
- Check existing issues and pull requests
- Review the documentation in the README and code comments

## License

By contributing to Instruktor, you agree that your contributions will be licensed under the MIT License.
