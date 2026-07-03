## CI/CD monitoring

Quand on me demande de vérifier les pipelines ou de diagnostiquer un échec CI/CD :

```bash
gh run list --branch $(git branch --show-current) --limit 5
gh run view <run-id> --log-failed
```

Identifier le job en échec, lire les logs, proposer un fix.
