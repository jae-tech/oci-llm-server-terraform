# OCI LLM Server Terraform

OCI Always Free 대상 ARM 서버 한 대와 Docker 실행 환경을 만드는 Terraform 템플릿입니다.

LLM 런타임이나 모델은 설치하지 않습니다.

생성된 서버에 원하는 Docker Compose 구성을 직접 배포할 수 있습니다.

## 생성되는 리소스

| 리소스 | 구성 |
|---|---|
| Compute | `VM.Standard.A1.Flex`, 4 OCPU, 24 GB RAM |
| OS | Ubuntu 24.04 ARM |
| Storage | 200 GB boot volume |
| Network | VCN, public subnet, Internet Gateway, public IP |
| Server tools | Docker Engine, Docker Compose plugin, UFW, fail2ban |

SSH 외 포트는 기본적으로 열리지 않습니다.

`terraform destroy`를 실행하면 인스턴스와 boot volume을 함께 삭제합니다.

## 주의사항

- Terraform은 과금을 차단하지 않습니다.
- OCI Free Tier 정책과 현재 사용량을 직접 확인해야 합니다.
- A1 Free Tier는 리전에 따라 용량 부족으로 생성에 실패할 수 있습니다.
- 서비스 포트를 `0.0.0.0/0`에 공개하면 인증되지 않은 API가 노출될 수 있습니다.
- 가능하면 서비스 포트를 공개하지 말고 SSH 터널을 사용하세요.
- `terraform.tfvars`, state 파일, OCI 개인키는 절대 커밋하지 마세요.

## 사전 준비

- OCI 계정과 사용할 compartment
- Terraform `>= 1.9`
- OCI API key가 설정된 `~/.oci/config`, 또는 직접 인증에 필요한 OCID와 개인키
- SSH key pair

SSH 키가 없다면 생성합니다.

```bash
ssh-keygen -t ed25519
```

## 설정

### 1. 변수 파일 생성

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars`에서 다음 값을 수정합니다.

- OCI 리전
- Compartment OCID
- SSH 공개키
- SSH 접속을 허용할 CIDR

SSH 허용 CIDR에는 자신의 공인 IP와 `/32`를 사용하는 것을 권장합니다.

### 2. OCI 인증 설정

기본 인증 방식은 `~/.oci/config`의 프로필입니다.

```hcl
oci_auth_mode       = "profile"
config_file_profile = "DEFAULT"
```

OCI config를 사용하지 않으려면 직접 인증 방식을 사용할 수 있습니다.

```hcl
oci_auth_mode     = "direct"
tenancy_ocid      = "ocid1.tenancy.oc1..xxxxxx"
user_ocid         = "ocid1.user.oc1..xxxxxx"
fingerprint       = "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
private_key_path  = "/absolute/path/to/oci_api_key.pem"
```

## 배포

```bash
terraform init
terraform plan
terraform apply
```

배포 후 SSH 접속 명령을 확인합니다.

```bash
terraform output -raw ssh_command
```

## SSH 터널로 LLM API 접속

예를 들어 LLM API가 서버의 `8000` 포트에서 실행 중이라면 다음 명령으로 로컬 터널을
생성합니다.

```bash
ssh -L 8000:localhost:8000 ubuntu@SERVER_PUBLIC_IP
```

터널이 연결된 동안 로컬 환경에서 `http://localhost:8000`으로 API에 접근할 수 있습니다.

## 추가 포트 공개

서비스 포트를 직접 공개해야 할 때만 `ingress_rules`를 추가합니다.

OCI Security List와 서버 UFW에 같은 규칙이 적용됩니다.

```hcl
ingress_rules = [
  {
    description = "LLM API"
    source      = "203.0.113.10/32"
    port        = 8000
  }
]
```

> [!IMPORTANT]
> cloud-init은 인스턴스 최초 생성 시에만 적용됩니다.
>
> 기존 인스턴스에서 규칙을 바꾸면 OCI Security List는 변경되지만 UFW는 자동으로
> 갱신되지 않습니다.
>
> 인스턴스를 다시 생성하거나 UFW 규칙을 직접 맞춰야 합니다.

## 용량 부족 재시도

먼저 plan을 저장하고 내용을 검토합니다.

```bash
terraform plan -out=llm.tfplan
```

검토한 plan 파일을 지정해 제한된 횟수만큼 적용을 재시도합니다.

```bash
RETRY_MAX_ATTEMPTS=20 RETRY_INTERVAL_SECONDS=60 bash retry.sh llm.tfplan
```

## 삭제

```bash
terraform destroy
```

이 명령은 boot volume도 삭제합니다.

필요한 데이터는 먼저 백업하세요.

## 공개 저장소로 올릴 때

실제 state와 `terraform.tfvars`가 커밋에 포함되지 않았는지 확인하세요.

기존 비공개 Git 이력에 개인 IP나 인증 정보가 있었다면 해당 이력을 공개 원격에 푸시하지
마세요.

정리된 현재 파일로 새 첫 커밋을 만드는 것이 안전합니다.

## 라이선스

[MIT](LICENSE)
