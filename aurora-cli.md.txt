
## Aurora RDS resotre

###  留意事項
Single-AZ DB インスタンスでこの DB スナップショットを作成すると、I/O が短時間中断します。
この時間は、DB インスタンスのサイズやクラスによって異なり、数秒から数分になります。


### ２．実施手順（Aurora以外のRDS）
> 作業は、AWS CLIで実施します
> 
### １． スナップショットの取得
・取得コマンド

```
aws rds create-db-snapshot \
 --db-instance-identifier databse-1 \
 --db-snapshot-identifier cli-snap-shot \
 --region ap-northeast-1
```
> スナップショット名に数字から始まる名前は、指定できないので注意！


`


### 2.スナップショットのコピー
{quote}
&color(red) {暗号化されていないRDSから直接暗号化したスナップショットを作成することはできない。一度スナップショットを作成し、それをコピーする際に暗号化することが可能となる。}
{/quote}

・取得コマンド

```
//実行例
aws rds copy-db-snapshot \
  --source-db-snapshot-identifier cli-snap-shot
  --target-db-snapshot-identifier cli-snap-shot-encrypted \
  --kms-key-id <kms_key_id> \
  --option-group-name default:postgres-12

//説明
aws rds copy-db-snapshot \
  --source-db-snapshot-identifier <コピー元スナップショット名>
  --target-db-snapshot-identifier <コピー先スナップショット名> \
 // 暗号化されていないスナップショットを暗号化するためのオプション
  --kms-key-id <暗号化に使用するKMSのキーID> \
  // 未指定の場合、スナップショット元のオプショングループを引き継がずデフォルトのオプショングループとなる。
  // そのためデフォルトから変更している場合は、明示的に指定が必要。
  --option-group-name <スナップショットに設定するオプショングループ>
```


### 3.スナップショットのからのRDSの復元（暗号化済みRDSの作成）
・復元対象のRDSの設定一覧の取得

```
aws rds describe-db-instances --db-instance-identifier database-1 > src-db.json
```

・スナップショットからの復元
[[【参考リンク】公式リファレンス:https://docs.aws.amazon.com/cli/latest/reference/rds/restore-db-instance-from-db-snapshot.html]]

```
// 実行例
aws rds restore-db-instance-from-db-snapshot \
 --db-instance-identifier braindb-encrypted \
 --db-snapshot-identifier encrypted-snap-braindb \
 --db-instance-class db.t3.micro \
 --db-subnet-group-name defaul \
 --no-multi-az \
 --vpc-security-group-ids sg-09db78045ca4371a9 \
 --availability-zone ap-northeast-1a \
 --profile seiryo-dev

//説明
aws rds restore-db-instance-from-db-snapshot \
 --db-instance-identifier <リストア後のDB名> \
 --db-snapshot-identifier <コピー元のスナップショット名> \
 --db-instance-class <インスタンスクラス> \
 --db-subnet-group-name <サブネットグループ名> \
 --no-multi-az \
 // セキュリティグループ。複数ある場合は、スペースで連続記載。
 --vpc-security-group-ids <セキュリティグループ名>
 // single AZで指定がある場合は、後から変更できないため必須！
 --availability-zone ap-northeast-1a \
```
{quote}
&color(red) {シングルAZ構成の場合、--availability-zone <value> でAZを指定すること！（復元後の変更はできない）}
{/quote}


・復元後ののRDSの設定一覧の取得

```
aws rds describe-db-instances --db-instance-identifier -restore-database-1 > dst-db.json
```

・復元前後のRDSの設定比較

```
diff src-db.json dst-db.json
```


#３．実施手順（Aurora）

Auroraの場合は、暗号化されていないスナップショットから直接暗号化されたDBクラスターを復元できる。}
Auroraについては、スナップショットからのclusterの復元後、DBインスタンスの作成が別途必要となる。}


###１． スナップショットの取得
・取得コマンド

```
aws rds create-db-cluster-snapshot \
 --db-cluster-identifier aurora-1 \
 --db-cluster-snapshot-identifier aurora-snap \
 --region ap-northeast-1
```




### 2.スナップショットのからのRDSの復元１（クラスタの復元）
・復元対象のRDSの設定一覧の取得

```
aws rds describe-db-clusters --db-cluster-identifier aurora-1 > src-db.json
```

・スナップショットからのクラスタの復元
[[【参考リンク】公式リファレンス:https://docs.aws.amazon.com/cli/latest/reference/rds/restore-db-cluster-from-snapshot.html]]

```
// 実行例
aws rds restore-db-cluster-from-snapshot \
 --db-cluster-identifier restore-aurora-1 \
 --snapshot-identifier aurora-snap \
 --engine aurora-postgresql
 --db-subnet-group-name default-vpc-28f2e34c \
 --vpc-security-group-ids sg-87989ee1 \
 --kms-key-id <kms_key_id> \

```


・復元後ののRDSの設定一覧の取得

```
aws rds describe-db-clusters --db-cluster-identifier restore-aurora-1 > dst-db.json
```
{quote}
&color(red) {この時点では、DBインスタンスが無いため"DBClusterMembers"は、空となります。}
{/quote}


・復元前後のRDSの設定比較

```
diff src-db.json dst-db.json
```


### ３.スナップショットのからのRDSの復元２（インスタンスの追加）
・DBインスタンスの追加
[[【参考リンク】公式リファレンス:https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html]]

```
// 実行例
aws rds create-db-instance \
 --db-cluster-identifier restore-aurora-1-2 \
 --db-instance-identifier restore-aurora-1-instance-1 \
 --db-instance-class db.t3.medium \
 --engine aurora-postgresql

```


