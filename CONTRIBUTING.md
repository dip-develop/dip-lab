# Contributing to Home Lab

Thank you for your interest in contributing!

## How to Contribute

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
4. **Commit** your changes (`git commit -m 'Add amazing feature'`)
5. **Push** to the branch (`git push origin feature/amazing-feature`)
6. **Open** a Pull Request

## Development Setup

```bash
# Clone repository
git clone https://github.com/yourusername/dm-home.git
cd dm-home

# Copy environment template
cp databases/.env.example databases/.env
cp automation/.env.example automation/.env
# ... copy other .env files as needed

# Edit with your configuration
vim databases/.env

# Setup and start
./manager.sh setup
./manager.sh start databases
./manager.sh start
```

## Guidelines

- Follow existing code style and conventions
- Use descriptive commit messages
- Test your changes before submitting
- Update documentation when needed
- Keep security in mind (don't commit secrets)

## Security

- Never commit actual passwords or API keys
- Use `.env` files for sensitive data (already in .gitignore)
- Report security issues via GitHub Issues or email

## License

By contributing, you agree that your contributions will be licensed under the MIT License.