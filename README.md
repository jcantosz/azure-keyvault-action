# azure-keyvault-action

Work in progress

GitHub action to read secrets from Azure Keyvault

```yaml
inputs:
  vault-name:  # id of input
    description: 'The vault to read from'
    required: true
  type:
    description: 'The type of resource to get (secret, key, certificate)'
    default: 'secret'
    required: true
  keys:
    description: 'The keys of the resource to get (comma-seperated)'
    required: true
  output-env:
    description: 'Create environment variables from the keys?'
    required: true
    default: 'true'
  output-outputs:
    description: 'Create outputs variables from the keys?'
    required: true
    default: 'false'
```
