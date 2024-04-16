
- スクリプト
  
```bash
#!/bin/bash

# カレントディレクトリのCSVファイルをソートして重複を排除
for file in *.csv; do
  sort "$file" | uniq > "sorted_$file"
done

echo "処理が完了しました。"
```

 - 実行権限設定

```
chmod +x script_name.sh
```

 - 実行

```
./script_name.sh
```
