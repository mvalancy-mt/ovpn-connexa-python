# Cursor Rules

This directory contains rules that guide AI behavior in this project. Each rule is designed to ensure consistent, high-quality development practices.

## Core Rules (Always Applied)

### `documentation-structure.mdc`
- **Purpose**: Ensures consistent documentation structure across the project
- **Justification**: 
  - Maintains navigable documentation hierarchy
  - Ensures all directories have proper README files
  - Enforces visual documentation standards
  - Keeps documentation interlinked

### `project-structure.mdc`
- **Purpose**: Defines core project organization principles
- **Justification**:
  - Maintains consistent code organization
  - Ensures proper Python package structure
  - Guides module organization
  - Preserves existing patterns

### `planning-tracking.mdc`
- **Purpose**: Manages project planning and progress tracking
- **Justification**:
  - Maintains clear planning structure
  - Tracks actual progress (not estimates)
  - Documents architectural decisions
  - Preserves implementation context

### `code-quality.mdc`
- **Purpose**: Enforces code quality and preservation standards
- **Justification**:
  - Prevents unnecessary code modifications
  - Controls file creation
  - Maintains code quality standards
  - Ensures proper code review

### `tdd-workflow.mdc`
- **Purpose**: Enforces test-driven development practices
- **Justification**:
  - Ensures tests are written first
  - Maintains code quality through testing
  - Guides implementation process
  - Preserves test coverage

### `ai-guidelines.mdc`
- **Purpose**: Guides AI agent behavior and communication
- **Justification**:
  - Ensures consistent AI behavior
  - Controls code modification patterns
  - Maintains documentation standards
  - Guides communication practices

### `git-workflow.mdc`
- **Purpose**: Defines git practices for agentic development
- **Justification**:
  - Ensures consistent commit messages
  - Maintains clean git history
  - Guides commit structure
  - Preserves change context

## Context-Specific Rules (Auto-Attached)

### `documentation-visual.mdc`
- **Purpose**: Provides visual documentation guidelines
- **Justification**:
  - Guides Mermaid diagram creation
  - Ensures consistent visual documentation
  - Provides diagram templates
  - Maintains visual standards

### `testing-qa.mdc`
- **Purpose**: Provides detailed testing guidelines
- **Justification**:
  - Guides test implementation
  - Ensures proper mocking
  - Manages integration tests
  - Maintains test quality

## Rule Types

### Always Applied
These rules are always included in the AI context to ensure consistent behavior:
- Documentation structure
- Project structure
- Planning tracking
- Code quality
- TDD workflow
- AI guidelines
- Git workflow

### Auto-Attached
These rules are included based on the context of the files being worked with:
- Visual documentation (when working with diagrams)
- Testing guidelines (when working with tests)

## Best Practices
- Keep rules focused and concise
- Update rules as project evolves
- Document rule changes
- Maintain rule consistency 