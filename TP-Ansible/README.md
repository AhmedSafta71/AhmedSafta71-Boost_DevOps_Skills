# TP Ansible — Kuikops

## Arborescence
```
tp-ansible/
├── terraform/            # Partie 1 : 2 EC2 Ubuntu 24.04 + disque EBS + SG + inventaire auto
├── inventory/            # hosts.ini généré par Terraform
├── group_vars/           # Variables (collègues, disque, rotation…)
├── files/public_keys/    # Clés publiques des collègues (*.pub)  <-- À REMPLACER
├── roles/
│   ├── ssh_keys/         # 1) comptes + clés SSH des collègues
│   ├── filesystem/       # 2) LVM : /var/www et /var/log/apache2
│   ├── apache2/          # 3) Apache + page Hello World (ansible_facts)
│   ├── logrotate/        # 4) rotation quotidienne /var/log/apache2
│   └── jenkins/          # Partie 3
├── site.yml              # Playbook principal (Partie 1)
├── jenkins.yml           # Partie 3
├── docs/commandes_manuelles.md

```

## Prérequis (poste de contrôle)
```bash
pip install ansible            # ou: sudo apt install ansible
ansible-galaxy collection install -r requirements.yml
# Terraform >= 1.5 + credentials AWS (aws configure)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519   # si vous n'avez pas de clé
```

## Partie 1
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # adaptez
terraform init && terraform apply
cd ..
ansible all -m ping                  # test de connexion
ansible-playbook site.yml            # tout le déploiement
# ou étape par étape :
ansible-playbook site.yml --tags ssh_keys
ansible-playbook site.yml --tags filesystem
ansible-playbook site.yml --tags apache2
ansible-playbook site.yml --tags logrotate
```
Vérification : ouvrir `http://<IP_publique>` de chaque instance.

## Partie 3 (Jenkins sur Host 1)
```bash
ansible-playbook jenkins.yml
```
Le mot de passe initial est affiché à la fin. Ouvrir `http://<IP_front1>:8080`.

## Partie 2 (optionnelle — GLPI)
```bash
cd partie2-glpi
ansible-galaxy collection install -r requirements.yml
cd terraform && terraform init && terraform apply && cd ..
ansible all -m ping
ansible-playbook site.yml
```
⚠️ Le NAT Gateway est payant : `terraform destroy` après le TP.

## Nettoyage
```bash
cd terraform && terraform destroy
```
