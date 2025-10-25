# Contributing to Sortyx CloudApp

Thank you for your interest in contributing to Sortyx CloudApp! 

## 🚀 Getting Started

1. Fork the repository on Bitbucket/Stash
2. Clone your fork locally
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit with clear messages
7. Push to your fork
8. Create a pull request

## 📝 Coding Standards

### Python Style Guide
- Follow PEP 8
- Use meaningful variable names
- Add docstrings to functions and classes
- Keep functions focused and small
- Maximum line length: 100 characters

### Code Formatting
```bash
# Format code (optional - install black first)
pip install black
black app.py

# Check linting
pip install flake8
flake8 app.py
```

## 🧪 Testing

Before submitting a PR:
1. Test the application locally
2. Check all endpoints work correctly
3. Verify Docker build succeeds
4. Test with different image inputs
5. Check logs for errors

```bash
# Test basic functionality
python -c "from app import app; print('✅ Import test passed')"

# Test Docker build
docker build -t test-cloudapp .
```

## 📋 Pull Request Process

1. **Update documentation** if you change functionality
2. **Add comments** to complex code sections
3. **Test thoroughly** before submitting
4. **Write clear PR description**:
   - What changes were made?
   - Why were they needed?
   - What was tested?

### PR Checklist
- [ ] Code follows project style guidelines
- [ ] Comments added for complex logic
- [ ] Documentation updated (if needed)
- [ ] Tested locally
- [ ] No breaking changes (or clearly documented)
- [ ] Requirements.txt updated (if dependencies changed)

## 🐛 Bug Reports

When reporting bugs, include:
- Python version
- Operating system
- Steps to reproduce
- Expected behavior
- Actual behavior
- Error messages/logs
- Screenshots (if applicable)

## 💡 Feature Requests

For new features:
- Explain the use case
- Describe expected behavior
- Consider backward compatibility
- Suggest implementation approach (optional)

## 📦 Commit Message Guidelines

Use clear, descriptive commit messages:

```
feat: Add new waste classification category
fix: Resolve hand detection timeout issue
docs: Update deployment guide
refactor: Optimize image processing pipeline
test: Add unit tests for classification
chore: Update dependencies
```

Prefix types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Testing
- `chore`: Maintenance

## 🔒 Security

If you discover a security vulnerability:
1. **DO NOT** open a public issue
2. Email the maintainers directly
3. Provide detailed information
4. Allow time for fix before disclosure

## 📞 Questions?

- Check existing documentation
- Review closed issues
- Ask in pull request comments
- Contact maintainers

Thank you for contributing! 🎉
