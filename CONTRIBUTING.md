# Contributing to DIP-Lab

Thanks for your interest in contributing!

## How to Contribute

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
4. **Commit** your changes (`git commit -m 'Add amazing feature'`)
5. **Push** to the branch (`git push origin feature/amazing-feature`)
6. **Open** a Pull Request

## Development Setup

```bash
git clone https://github.com/dip-develop/dip-lab.git
cd dip-lab

# Copy the env template for each service you intend to run
cp databases/.env.example databases/.env
cp proxy/.env.example proxy/.env
# ... repeat per service

# Edit with your configuration
vim databases/.env

# Setup and start
./manager.sh setup
./manager.sh start databases
./manager.sh start
```

The `dev-agents` container is opt-in. If you want to develop against it
locally:

```bash
cp dev-agents/.env.example dev-agents/.env
# fill in DEVELOP_UID, DEVELOP_GID, OPENCODE_SERVER_PASSWORD
./manager.sh start dev-agents
```

## Guidelines

- Follow existing code style and conventions (Compose, shell, Markdown)
- Use descriptive commit messages
- Test your changes before submitting (start the affected service, check
  logs, exercise the change)
- Update documentation when needed (`AGENTS.md`, `README.md`,
  service-specific READMEs)
- Keep security in mind — never commit secrets

## Project layout

```
.
├── manager.sh                 # primary entrypoint script
├── AGENTS.md                  # contributor/operator agent guide
├── README.md                  # user-facing docs
├── SECURITY.md                # vulnerability disclosure
├── CONTRIBUTING.md            # this file
├── LICENSE                    # MIT
├── completions.bash           # bash tab-completion
├── networks.yml               # (currently unused; networks live in manager.sh)
├── .disabled_services.example # template for the .disabled_services file
├── .profiles/                 # built-in service profiles
├── databases/  proxy/  monitoring/  passwords/  containers/
├── cloud/      docs/    automation/  gallery/    ai-agent/
└── dev-agents/                # opt-in developer workstation container
```

## Security

- Never commit real passwords, API keys, or tokens
- Use `.env` files for sensitive data (already in `.gitignore`)
- Report security issues via `SECURITY.md`, not GitHub Issues

## License

By contributing, you agree that your contributions will be licensed
under the MIT License.
