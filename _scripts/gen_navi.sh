#!/bin/bash

function gen_navibar() {
   # 当前目录
  local currentDir=$1
  local targetFile="$currentDir/_navbar.md"
  echo "* [Home](/)" > "$targetFile"
  for item in "$currentDir"/*; do
    if [ -d "$item" ] && [[ $(basename "$item") != _* ]]; then
      local item_name=$(basename "$item")
      echo "* [${item_name%.*}](/${item_name%.*}/)" >> "$targetFile"
    fi
  done
  echo "* [关于我](/_about/)" >> "$targetFile"
}

# 生成内容索引
function gen_index() {
  local folder=$1
  local baseDir=$2
  local dirName=$(basename "$folder" )
  echo -e "\ngen_index $folder $baseDir"
  local readme="$folder/README.md"
  if [ -z "$pathToBaseDir" ];then
    echo "# Home" > "$readme"
  else
    echo "# $dirName" > "$readme"
  fi
  echo "" >> "$readme"

  for item in "$folder"/*; do
    if [ -d "$item" ] && [[ $(basename "$item") != _* ]]; then
      local item_name=$(basename "$item")
      echo "- [${item_name%.*}]($baseDir/${item_name%.*}/)" >> "$readme"
      gen_index "$item" "$baseDir/$item_name"
    elif [ -f "$item" ] && [[ $(basename "$item") != _* ]] && [[  $(basename "$item") != index* ]]; then
      local item_name=$(basename "$item" )
      echo "item_name=$item_name"
      if [ "$item_name" != "_navibar.md" ] && [[ "$item_name" != README* ]];then
        echo "- [${item_name%.*}]($baseDir/${item_name%.*}.md)" >> "$readme"
        #echo "is $item_name readme"
      else
        echo "Skip:$item"
      fi
    fi
  done
}


# 生成侧边栏
function gen_sidebar() {
  # 当前目录
  local currentDir=$1
  #到根目录的相对路径
  local pathToBaseDir=$2 
  # 父目录的目标写入文件
  local parentFile=$3
  # 前缀
  local prefix=$4
  if [ -z "$prefix" ];then
    prefix="*"
  fi
  # 当前目录名称
  local dirName=$(basename "$currentDir")

  echo  "\ngen_sidebar currentDir=$currentDir pathToBaseDir=$pathToBaseDir dirName=$dirName prefix=$prefix"

  #当前要写入的文件
  local targetFile="$currentDir/_sidebar.md"

  echo  "\n" >> "$targetFile"
  if [ -z "$pathToBaseDir" ];then
      echo  "$prefix Home" > "$targetFile"
  else
      echo  "$prefix $dirName" > "$targetFile"
  fi

  # 遍历当前目录
  for item in "$currentDir"/*; do
    # 目录
    if [ -f "$item" ] && [[ $(basename "$item") != _* ]]; then
      local item_name=$(basename "$item" )
      echo  "item_name=$item_name"
      if [ "$item_name" != "README.md" ] && [[ $item_name != index* ]];then
        # 写入到上层中
        if [ -f "$parentFile" ];then
            echo  "  $prefix [${item_name%.*}]($pathToBaseDir/${item_name%.*}.md)" >> "$parentFile"
        fi
        echo  "  $prefix [${item_name%.*}]($pathToBaseDir/${item_name%.*}.md)" >> "$targetFile"
        #echo "is $item_name readme"
      else
        echo "Skip: $item"
      fi
    fi
  done
 
  # 遍历当前目录
  for item in "$currentDir"/*; do
    # 目录
    if [ -d "$item" ] && [[ $(basename "$item") != _* ]]; then
      # 获取目录名称
      local item_name=$(basename "$item")
      echo  "$prefix ${item_name%.*}" >> "$targetFile"
      local childDirToBaseDirPath="$pathToBaseDir/$item_name"
      gen_sidebar "$item" $childDirToBaseDirPath $targetFile "$prefix"
    fi
  done

  
}


function refresh_navibar(){
   gen_navibar  "$(pwd)" ""
}

function refresh_index(){
   gen_index "$(pwd)" "" "\*"
}

function refresh_sidebar(){
  gen_sidebar "$(pwd)" ""
}

if [ "$1" = "start" ];then
  refresh_index
  refresh_navibar
  refresh_sidebar
fi



