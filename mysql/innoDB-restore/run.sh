#!/usr/bin/env bash


input_dir=".frm文件目录"
output_file="./output.sql"

find "$input_dir" -type f -name "*.frm" | while read -r frm_file; do   
    # 执行 dbsake frmdump 命令并追加输出到文件
    ~/bin/dbsake frmdump "$frm_file" >> "$output_file" 2>&1
    echo -e "\n" >> "$output_file"
done