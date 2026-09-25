# TP Terraform – Kodemade / Tech Mind — `safta_ahmed`

Infrastructure AWS (région Paris `eu-west-3`) déployée en IaC avec Terraform, backend distant S3 + verrou DynamoDB,
en deux versions : **Partie 01 sans modules** et **Partie 02 avec modules**.

## Arborescence

```
tp-terraform-safta_ahmed/
├── 00-bootstrap/                 # Étape 0 (state local) : table DynamoDB de lock + dossiers safta/ et safta_modules/ dans le bucket
├── partie-01-sans-modules/       # state -> s3://techmind-terraform-state/safta/terraform.tfstate
│   ├── main.tf  providers.tf  variables.tf  terraform.tfvars  outputs.tf
│   ├── user_data/ (docker.sh, nodejs.sh)
│   └── lambda/ec2_scheduler.py
├── partie-02-avec-modules/       # state -> s3://techmind-terraform-state/safta_modules/terraform.tfstate
│   ├── main.tf  providers.tf  variables.tf  terraform.tfvars  outputs.tf
│   ├── user_data/
│   └── modules/ subnet/ sg/ iam_ec2/ keypair/ ec2/ s3/ scheduler/
├── iam/terraform-deployer-policy.json   # policy "moindre privilège" pour l'identité qui lance Terraform
└── scripts/verify.sh                    # vérification SSH + SSM
```

## Ce qui est créé

| Élément | Partie 01 (nom) | Partie 02 (nom) |
|---|---|---|
| Subnet public / privé | `tech_mind_iac_safta_ahmed_subnet_public/_private` | `techmind_iac_module_safta_ahmed_subnet_public/_private` |
| Tables de routage | `..._rt_public` (→ IGW existante) / `..._rt_private` (→ NAT existante) | idem |
| Security groups | `..._sg_public` / `..._sg_private` | idem |
| Rôle + profil EC2 | `..._role_ec2_ssm` + `..._instance_profile_ssm` (AmazonEC2RoleForSSM) | idem |
| Serveur 1 public | `..._ec2_docker` (t3.micro, AL2023, 8 Go gp3 chiffré, IMDSv2) | idem |
| Serveur 2 privé | `..._ec2_nodejs` (idem, sans IP publique) | idem |
| 2 buckets S3 | `tech-mind-iac-safta-ahmed-s3-01-xxxx` / `-02-` | `techmind-iac-module-safta-ahmed-s3-01-xxxx` / `-02-` |
| Lambda | `..._lambda_ec2_scheduler` | idem |
| EventBridge Scheduler | `..._schedule_stop_ec2` (19h) / `..._schedule_start_ec2` (9h), fuseau Europe/Paris | idem |
| Lock DynamoDB | `tech_mind_safta_ahmed_dynamodb_tflock` (commun) | |

> Les noms de buckets S3 utilisent des tirets : AWS **interdit les `_`** dans les noms de bucket. Le tag `Name` du bucket garde la nomenclature avec underscores.

Tous les objets reçoivent les tags : `Owner=safta_ahmed`, `Project`, `Environment`, `ManagedBy=terraform`, `Part`, plus `Name`.

---

## 1. Prérequis sur votre poste

- Terraform ≥ 1.6 — `terraform -version`
- AWS CLI v2 — `aws --version`
- Plugin **Session Manager** pour l'AWS CLI (obligatoire pour SSM et SSH-over-SSM) :
  https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
- Clé SSH dédiée au TP :

```bash
ssh-keygen -t ed25519 -f ~/.ssh/tech_mind_safta_ahmed -C "safta_ahmed tp terraform"
```

---

## 2. S'authentifier auprès d'AWS (le provider Terraform)

**Règle d'or : aucune clé dans les fichiers `.tf`.** Le provider AWS lit automatiquement la chaîne d'identifiants standard ; on
sélectionne un profil avec la variable `AWS_PROFILE`.

### Option A — recommandée : IAM Identity Center (SSO), identifiants temporaires

Si votre compte formation propose un portail SSO (`https://xxxx.awsapps.com/start`) :

```bash
aws configure sso --profile tech-mind-safta
#   SSO start URL : <fourni par le formateur>
#   SSO region    : <région du portail>
#   compte + rôle : choisir votre rôle
#   default region: eu-west-3
aws sso login --profile tech-mind-safta
export AWS_PROFILE=tech-mind-safta          # PowerShell : $env:AWS_PROFILE="tech-mind-safta"
aws sts get-caller-identity                 # doit afficher votre identité
```

Avantage : jetons temporaires (quelques heures), rien de sensible stocké durablement.

### Option B — si vous n'avez qu'un utilisateur IAM : access key dans un profil nommé

1. Console IAM → votre utilisateur (ex. `tech_mind_safta_ahmed_terraform`) → *Security credentials* → *Create access key* → cas d'usage **CLI**.
2. Idéalement, faites attacher la policy `iam/terraform-deployer-policy.json` à cet utilisateur (moindre privilège), et activez le MFA.
3. Configurez le profil :

```bash
aws configure --profile tech-mind-safta
#   AWS Access Key ID     : AKIA...
#   AWS Secret Access Key : ...
#   Default region name   : eu-west-3
#   Default output format : json
export AWS_PROFILE=tech-mind-safta
aws sts get-caller-identity
```

Les clés vont dans `~/.aws/credentials` (hors du projet). Ne jamais les commiter, les faire tourner régulièrement, les supprimer à la fin du TP.

> Un « rôle IAM » ne peut pas être utilisé directement depuis votre PC : il faut une identité de départ (SSO ou utilisateur) qui l'assume.
> En revanche, si vous lancez Terraform **depuis une EC2 ou CloudShell**, le rôle attaché est utilisé automatiquement, sans aucune clé.

### La policy du déployeur (`iam/terraform-deployer-policy.json`)

Elle n'autorise que : votre préfixe dans le bucket de state, votre table de lock, la région Paris pour EC2, la suppression uniquement des
ressources EC2 taguées `Owner=safta_ahmed`, les rôles/Lambda/log groups/schedules/buckets dont le nom commence par vos préfixes,
`iam:PassRole` limité aux services EC2/Lambda/Scheduler, et l'attachement des seules policies SSM. Si votre compte de formation vous
donne déjà des droits admin, elle est optionnelle mais c'est ce qu'il faut montrer pour le « moindre privilège ».

---

## 3. Éléments à vérifier / changer AVANT de lancer

| Fichier | Variable | Pourquoi |
|---|---|---|
| `*/terraform.tfvars` | `public_subnet_cidr`, `private_subnet_cidr` | **VPC partagé** : les plages doivent être libres (voir commande ci-dessous). Partie 01 : `10.0.201.0/24`, `10.0.202.0/24` ; Partie 02 : `10.0.203.0/24`, `10.0.204.0/24`. |
| `*/terraform.tfvars` | `availability_zone` | `eu-west-3a` par défaut. |
| `*/terraform.tfvars` | `default_tags` | Ajouter/adapter les tags exigés par le formateur. Garder `Owner = "safta_ahmed"` (utilisé par la policy IAM). |
| `*/terraform.tfvars` | `allowed_ssh_cidr` | Vide = votre IP publique est détectée automatiquement. Sinon mettre `x.x.x.x/32`. |
| `*/terraform.tfvars` | `ssh_public_key_path` | Si votre clé porte un autre nom. |
| `*/terraform.tfvars` | `stop/start_schedule_expression` | Tous les jours par défaut. Jours ouvrés seulement : `cron(0 19 ? * MON-FRI *)` et `cron(0 9 ? * MON-FRI *)`. |
| `*/providers.tf` | bloc `backend "s3"` | Valeurs en dur (Terraform n'accepte pas de variables ici) : bucket, clé `safta/...`, table de lock. |
| `*/terraform.tfvars` | `vpc_id`, `igw_id`, `nat_gateway_id` | Déjà renseignés avec les IDs du TP. |

Vérifier les CIDR déjà utilisés dans le VPC :

```bash
aws ec2 describe-subnets --region eu-west-3 \
  --filters Name=vpc-id,Values=vpc-02855c98755e6b058 \
  --query 'Subnets[].[CidrBlock,Tags[?Key==`Name`]|[0].Value]' --output table
```

---

## 4. Étape préalable du TP : supprimer les ressources du TP AWS

Listez ce qui vous appartient encore (créé à la main lors du TP AWS) :

```bash
aws ec2 describe-instances --region eu-west-3 \
  --filters "Name=tag:Name,Values=*safta*" "Name=instance-state-name,Values=pending,running,stopped" \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`]|[0].Value,State.Name]' --output table
aws ec2 describe-security-groups --region eu-west-3 --filters "Name=group-name,Values=*safta*" --query 'SecurityGroups[].[GroupId,GroupName]' --output table
aws ec2 describe-subnets --region eu-west-3 --filters "Name=tag:Name,Values=*safta*" --query 'Subnets[].[SubnetId,CidrBlock]' --output table
aws ec2 describe-key-pairs --region eu-west-3 --filters "Name=key-name,Values=*safta*" --output table
```

Supprimez dans cet ordre : instances → (attendre *terminated*) → security groups → associations/tables de routage → subnets → key pairs →
rôles IAM / instance profiles. Ne touchez **jamais** au VPC, à l'IGW ni au NAT partagés.

---

## 5. Étape 0 — Bootstrap (lock DynamoDB + dossiers dans le bucket)

```bash
cd 00-bootstrap
terraform init
terraform apply
```

Résultat : table `tech_mind_safta_ahmed_dynamodb_tflock` + dossiers `safta/` et `safta_modules/` dans `techmind-terraform-state`.
Ce petit state reste local (`00-bootstrap/terraform.tfstate`) : gardez-le jusqu'à la fin du TP.

> Terraform ≥ 1.11 affiche un avertissement : `dynamodb_table` est déprécié au profit de `use_lockfile = true` (lock natif S3).
> Le lock DynamoDB demandé fonctionne toujours ; pour passer au lock natif plus tard, remplacer la ligne `dynamodb_table` par `use_lockfile = true`.

---

## 6. Partie 01 — sans modules

```bash
cd ../partie-01-sans-modules
terraform init          # se connecte au backend S3 + DynamoDB
terraform fmt -check
terraform validate
terraform plan -out tfplan
terraform apply tfplan
terraform output
```

Attendez 2–3 minutes après l'apply : le `user_data` installe et démarre SSM Agent, Docker et Node.js
(le serveur privé passe par la NAT). Le state est visible dans `s3://techmind-terraform-state/safta/terraform.tfstate`.

---

## 7. SSH du serveur public vers le serveur privé

### Méthode 1 — Bastion avec `ProxyJump` (la clé privée ne quitte jamais votre PC)

```bash
terraform output -raw ssh_config >> ~/.ssh/config
ssh safta-public       # serveur Docker (public)
ssh safta-private      # serveur Node.js (privé), rebond transparent via le public
```

Le rebond est chiffré de bout en bout ; aucune clé n'est copiée sur le bastion (ne faites pas de `scp` de votre clé privée, et évitez
`ssh -A` : un bastion compromis pourrait utiliser votre agent). Côté réseau, le SG privé n'accepte le port 22 **que** depuis le SG public,
et le SG public n'accepte le 22 **que** depuis votre IP.

### Méthode 2 — meilleure pratique : SSH tunnelé dans SSM

```bash
ssh safta-public-ssm
ssh safta-private-ssm
```

La connexion passe par Session Manager (HTTPS sortant de l'instance) : pas besoin d'IP publique ni de port 22 ouvert depuis Internet,
chaque session est authentifiée par IAM et journalisée par AWS. C'est la configuration recommandée en production ; la règle SSH admin
peut alors être supprimée.

> Windows (OpenSSH) : dans la ligne `ProxyCommand`, préfixez par
> `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe "aws ssm start-session ..."`.

### Session SSM pure (sans SSH)

```bash
aws ssm start-session --target $(terraform output -raw public_instance_id)  --region eu-west-3
aws ssm start-session --target $(terraform output -raw private_instance_id) --region eu-west-3
```

---

## 8. Vérifier SSM Agent + logiciels (SSH **et** SSM)

```bash
cd ..
./scripts/verify.sh partie-01-sans-modules
```

Le script teste en SSH : `amazon-ssm-agent` et `docker` actifs + `docker run hello-world` sur le public ; `amazon-ssm-agent`, `node --version`
et l'appli `node-hello` (port 3000 local) sur le privé via le rebond. Puis en SSM : statut `Online` des deux instances et
`send-command` (AWS-RunShellScript) qui renvoie l'état des services.

Commandes manuelles équivalentes, une fois connecté :

```bash
sudo systemctl status amazon-ssm-agent
sudo systemctl status docker && docker --version        # serveur public
node --version && curl -s localhost:3000                # serveur privé
sudo cat /var/log/user-data.log                         # en cas de problème
```

---

## 9. Tester l'arrêt / démarrage automatique

```bash
cd partie-01-sans-modules
eval "$(terraform output -json ssm_commands | jq -r .test_stop)"
eval "$(terraform output -json ssm_commands | jq -r .test_start)"
```

Logs : CloudWatch → `/aws/lambda/tech_mind_iac_safta_ahmed_lambda_ec2_scheduler`. Planifications : EventBridge → Scheduler → Schedules.

L'IP publique du serveur Docker change après un stop/start (pas d'Elastic IP) : lancez `terraform apply -refresh-only` puis régénérez
le bloc `ssh_config`. Les alias `*-ssm` utilisent l'ID d'instance et ne sont pas concernés.

---

## 10. Partie 02 — avec modules + migration du state

Le TP demande de migrer le state vers `safta_modules/terraform.tfstate` avec `terraform init -migrate-state`.

```bash
cd ../partie-02-avec-modules

# 1) Récupérer la configuration backend de la partie 01 (clé safta/terraform.tfstate)
cp -r ../partie-01-sans-modules/.terraform .
cp ../partie-01-sans-modules/.terraform.lock.hcl .
#    PowerShell : Copy-Item -Recurse ..\partie-01-sans-modules\.terraform . ; Copy-Item ..\partie-01-sans-modules\.terraform.lock.hcl .

# 2) providers.tf pointe sur safta_modules/terraform.tfstate -> Terraform détecte le changement
terraform init -migrate-state
#    "Do you want to copy existing state to the new backend?" -> yes

# 3) Appliquer la version modulaire
terraform plan -out tfplan
terraform apply tfplan
```

Le plan **détruit** les ressources `tech_mind_iac_safta_ahmed_*` (qui ne sont plus dans le code) et **crée** les
`techmind_iac_module_safta_ahmed_*`. Les noms et les CIDR sont différents justement pour éviter les conflits pendant ce remplacement.
Ensuite : `ssh safta-mod-public`, `ssh safta-mod-private`, `./scripts/verify.sh partie-02-avec-modules`.

Après la migration, ne relancez plus `apply` dans `partie-01-sans-modules` : son ancien state (`safta/terraform.tfstate`) est désormais obsolète.

---

## 11. Nettoyage en fin de TP

```bash
cd partie-02-avec-modules && terraform destroy
cd ../00-bootstrap && terraform destroy     # en dernier : supprime la table de lock et les dossiers
```

Supprimez aussi l'access key IAM si vous avez utilisé l'option B.

---

## 12. Choix de sécurité (à présenter)

- **Réseau** : le serveur Node.js n'a pas d'IP publique ; sortie via la NAT. SSH entrant limité à votre IP /32 → bastion → privé (référence de SG, pas de CIDR).
- **Egress restreint** : seul HTTPS 443 sort (dépôts dnf AL2023, Docker Hub, endpoints SSM) + SSH du bastion vers le SG privé. Aucune règle « tout ouvert ».
- **EC2** : IMDSv2 obligatoire, EBS gp3 chiffré, clé SSH dont seule la partie publique est envoyée à AWS.
- **IAM** : rôle EC2 dédié ; rôle Lambda limité à `StartInstances`/`StopInstances` sur **les ARN de vos 2 instances** et à son propre log group ;
  rôle Scheduler limité à `lambda:InvokeFunction` sur **votre** Lambda, avec condition `aws:SourceAccount` (anti « confused deputy »).
- **S3** : Block Public Access complet, ACL désactivées, chiffrement SSE-S3, versioning, refus de tout accès non-TLS.
- **State** : chiffré dans S3, isolé par préfixe, verrouillé par DynamoDB.
- **Planification** : EventBridge Scheduler avec fuseau `Europe/Paris` (9h/19h restent justes au changement d'heure, contrairement à un cron UTC).

**À propos d'`AmazonEC2RoleForSSM`** : c'est ce qu'impose la consigne, donc c'est la valeur par défaut de `ec2_ssm_policy_arn`. AWS la
considère comme dépréciée et trop large (elle donne notamment des droits S3 sur `*`). La policy recommandée et plus restreinte est
`arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore` : il suffit de changer la variable dans `terraform.tfvars`. Bon point à mentionner
à l'oral.

---

## 13. Dépannage

| Symptôme | Cause probable / solution |
|---|---|
| `Error acquiring the state lock` | Un autre `apply` tourne, ou un lock est resté après un crash : `terraform force-unlock <LOCK_ID>`. |
| `InvalidSubnet.Conflict` | CIDR déjà pris dans le VPC partagé : changer `*_subnet_cidr`. |
| `AccessDenied` sur `iam:CreateRole` | Vos droits ne permettent pas IAM : demandez au formateur d'attacher `iam/terraform-deployer-policy.json`. |
| Instance privée absente de SSM | NAT ou route manquante : vérifier `..._rt_private` → `nat-1522f5fbe634d3413` et `/var/log/user-data.log`. |
| SSH timeout sur le public | Votre IP a changé : `terraform apply` (détection automatique) ou fixer `allowed_ssh_cidr`. |
| `SessionManagerPlugin is not found` | Installer le plugin Session Manager (section 1). |
| Nom de bucket déjà pris | Le suffixe aléatoire évite ce cas ; sinon `terraform apply -replace=random_id.bucket_suffix`. |
