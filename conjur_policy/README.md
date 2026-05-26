# conjur_policy

Policy-as-code for the Murphys Lab Conjur Cloud tenant. The repo mirrors the
live policy tree returned by `conjur list` and is the source of truth for
every user, group, host, variable, webservice, and authenticator under the
`conjur/` and `data/` branches.

## Layout

```
conjur_policy/
├── root.yml                      # Users, root-level groups, top-level !policy stubs
├── load-policy.sh                # Loader that applies every file in dependency order
│
├── conjur/                       # System policies (loaded into branch: conjur)
│   ├── authn-iam.yml             #   AWS IAM authenticator (with /default service-id)
│   ├── authn-gcp.yml             #   Google Cloud authenticator
│   ├── authn-jwt.yml             #   JWT authenticator parent (add per-service-id children)
│   ├── authn-azure.yml           #   Azure authenticator parent
│   ├── authn-cert.yml            #   Certificate authenticator parent
│   └── issuers.yml               #   Dynamic-secrets issuers parent
│
└── data/                         # Application data (loaded into branch: data)
    ├── data.yml                  #   Admin groups, loose hosts, sub-policy stubs
    ├── terraform.yml             #   Terraform automation variables + host
    ├── static.yml                #   Statically-managed secrets (container)
    ├── dynamic.yml               #   Dynamic secrets (container)
    ├── swa.yml                   #   Secure Workload Access trust-domains
    └── vault/                    # Privilege Cloud safe syncs (loaded into branch: data/vault)
        ├── vault.yml             #   Per-safe admin groups + safe !policy stubs
        ├── m-aws-keys.yml
        ├── m-aws-pem-unmanaged.yml
        ├── m-conjur-automation.yml
        ├── m-priv-svc-accts.yml
        └── Trevor-AWS-Test.yml
```

## Conventions

- **Sub-policy stubs.** Parent files (`root.yml`, `data/data.yml`,
  `data/vault/vault.yml`) declare each child as a `!policy id: <name> body: []`.
  The child's actual contents live in its own file and are loaded into the
  parent branch with `conjur policy load -b <parent-branch> <file>`. This lets
  ownership and review of each branch live with its own file.
- **Vault safes.** Each PCloud safe maps 1:1 to a file in `data/vault/`. Inside
  each safe file, every account is a nested `!policy` whose body contains the
  account properties (`username`, `password`, `address`, `KeyID`,
  `AWSAccessKeyID`, `AWSAccountID`, `Region`, ...) as `!variable` entries. A
  `delegation` sub-policy holds the `consumers` group with read/execute on
  every variable in the safe.
- **Admin groups.** Per-branch and per-safe admin groups live in the
  *parent* file (e.g. `m-aws-keys-admins` is declared in `data/vault/vault.yml`,
  not in `data/vault/m-aws-keys.yml`), matching the `conjur list` output.
- **Permissions.** Each variable group is granted to its delegation
  consumers group inside the same file, so a file is self-contained
  (declare + grant) for its own resources.

## Loading

Make sure the Conjur CLI is installed and authenticated:

```bash
conjur init -u https://<tenant>.secretsmgr.cyberark.cloud/api -a conjur
conjur login -i <admin-user> -p <api-key>
```

Then run the loader:

```bash
./load-policy.sh             # default: full "policy load" (replace contents)
./load-policy.sh --update    # additive "policy update" (no deletes)
./load-policy.sh --dry-run   # print the commands without executing
```

### Load order (what the script does)

1. `root.yml` into `root` - creates users, root groups, and the `conjur` and
   `data` policy stubs.
2. Every file under `conjur/` into `conjur` - authenticators and issuers.
3. `data/data.yml` into `root` - data admin groups, loose hosts, and
   sub-policy stubs (`terraform`, `static`, `dynamic`, `swa`, `vault`).
4. `data/terraform.yml`, `data/static.yml`, `data/dynamic.yml`, `data/swa.yml`
   into `data`.
5. `data/vault/vault.yml` into `data` - per-safe admin groups + safe stubs.
6. Each `data/vault/<safe>.yml` into `data/vault` - accounts, variables, and
   delegation consumers.

This order respects the dependency between a sub-policy and its parent stub:
the parent must exist before the child can be loaded into the parent's branch.

## Adding new resources

| Want to add...                  | Edit                                              | Load into branch |
|---------------------------------|---------------------------------------------------|------------------|
| A new human user                | `root.yml`                                        | `root`           |
| A new account in an existing safe | `data/vault/<safe>.yml` (new nested `!policy`)  | `data/vault`     |
| A brand-new vault safe          | `data/vault/vault.yml` (admin group + stub) + new `data/vault/<safe>.yml` | `data` then `data/vault` |
| A new JWT authenticator service-id | new `!policy` block inside `conjur/authn-jwt.yml` | `conjur`         |
| Membership change               | The file that owns the group                      | that group's parent branch |

After editing, re-run `./load-policy.sh --update` to apply additive changes,
or `./load-policy.sh` for a full replace of the affected branches.

## Notes on `authn-oidc/cyberark`

The OIDC authenticator and its `cyberark` service-id are managed by Conjur
Cloud automatically when SSO is enabled in the tenant. For completeness this
repo declares the `!webservice cyberark` under a `conjur/authn-oidc` policy
in `root.yml`. If the tenant already owns this resource, the loader will
no-op on it during `policy update`.
