# Contributing to RustFS Deployment

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Description**: Clear description of the issue
- **Steps to Reproduce**: Detailed steps to reproduce the behavior
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Environment**: OS, Docker version, etc.
- **Logs**: Relevant log output

**Bug Report Template:**

```markdown
## Description
Brief description of the issue

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: Ubuntu 22.04
- Docker: 24.0.0
- Docker Compose: 2.20.0

## Logs
```
Paste relevant logs here
```
```

### Suggesting Enhancements

Enhancement suggestions are welcome! Please include:

- **Use Case**: Why is this enhancement needed?
- **Proposed Solution**: How should it work?
- **Alternatives**: Other solutions you've considered
- **Additional Context**: Screenshots, examples, etc.

### Pull Requests

1. **Fork the Repository**
   ```bash
   git clone https://github.com/yourusername/selfhosted-rustfs.git
   cd selfhosted-rustfs
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**
   - Follow existing code style
   - Update documentation
   - Add tests if applicable

4. **Test Your Changes**
   ```bash
   # Test locally
   make stop
   make up
   make logs
   ```

5. **Commit Changes**
   ```bash
   git add .
   git commit -m "Add feature: description"
   ```

   **Commit Message Guidelines:**
   - Use present tense ("Add feature" not "Added feature")
   - Use imperative mood ("Move cursor to..." not "Moves cursor to...")
   - Limit first line to 72 characters
   - Reference issues and pull requests

6. **Push to Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create Pull Request**
   - Provide clear description
   - Reference related issues
   - Include screenshots if applicable

## Development Setup

### Prerequisites

- Docker and Docker Compose
- Git
- Text editor

### Local Development

```bash
# Clone repository
git clone https://github.com/yourusername/selfhosted-rustfs.git
cd selfhosted-rustfs

# Create development environment
cp .env.example .env.dev
nano .env.dev

# Start services
docker compose up

# View logs
docker compose logs -f
```

### Testing Changes

#### Test Nginx Configuration

```bash
# Test nginx config syntax
docker exec rustfs-nginx nginx -t

# Reload nginx
docker exec rustfs-nginx nginx -s reload
```

#### Test Docker Compose

```bash
# Validate compose file
docker compose config

# Start services
docker compose up -d

# Check status
docker compose ps
```

#### Test SSL Setup

```bash
# Test with self-signed certificates
make ssl-setup

# Verify certificates
curl -k https://localhost/health
```

## Project Structure

```
selfhosted-rustfs/
├── .env.example           # Example environment configuration
├── docker-compose.yml     # Docker services definition
├── Makefile              # Management commands
├── setup-ssl.sh          # SSL setup automation
├── nginx/
│   ├── nginx.conf        # Main nginx configuration
│   └── conf.d/
│       └── rustfs.conf   # RustFS-specific nginx config
├── docs/                 # Documentation
│   ├── README.md
│   ├── DEPLOYMENT.md
│   └── QUICKSTART.md
└── scripts/              # Utility scripts
```

## Coding Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Include error handling (`set -e`)
- Add comments for complex logic
- Use meaningful variable names
- Quote variables: `"$VARIABLE"`

**Example:**
```bash
#!/bin/bash
set -e

# Description of what this script does
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d)

if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi
```

### Docker Compose

- Use version 3.8+
- Include restart policies
- Use environment variables
- Add comments for complex configurations
- Follow Docker best practices

### Nginx Configuration

- Use clear location blocks
- Include comments
- Follow nginx best practices
- Test configuration before committing

### Documentation

- Use Markdown format
- Include code examples
- Keep language clear and concise
- Update table of contents
- Add screenshots when helpful

## Documentation Guidelines

### README.md

- Overview and features
- Quick start guide
- Detailed usage instructions
- Troubleshooting section
- Links to other documentation

### DEPLOYMENT.md

- Step-by-step deployment guide
- Production considerations
- Security hardening
- Monitoring setup

### Code Comments

```bash
# Good: Explains why
# Create backup before making changes to prevent data loss
make backup

# Bad: Explains what (obvious from code)
# Run make backup
make backup
```

## Testing Checklist

Before submitting a pull request:

- [ ] Code follows project style
- [ ] Documentation updated
- [ ] Tested locally
- [ ] No breaking changes (or documented)
- [ ] Commit messages are clear
- [ ] Branch is up to date with main

## Review Process

1. **Automated Checks**: CI/CD runs automated tests
2. **Code Review**: Maintainers review code
3. **Testing**: Changes tested in staging environment
4. **Approval**: At least one maintainer approval required
5. **Merge**: Changes merged to main branch

## Release Process

1. Version bump in relevant files
2. Update CHANGELOG.md
3. Create release tag
4. Build and test release
5. Publish release notes

## Getting Help

- **Documentation**: Check existing docs first
- **Issues**: Search existing issues
- **Discussions**: Use GitHub Discussions for questions
- **Discord**: Join our community (if applicable)

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in documentation

## License

By contributing, you agree that your contributions will be licensed under the Apache 2.0 License.

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion
- Reach out to maintainers

Thank you for contributing! 🎉
