import os
import sys

def traverse_directory(path):
    for root, dirs, files in os.walk(path):
        print("当前目录：", root)
        print("子目录：", dirs)
        print("文件：", files)
        print()

def main():
    if len(sys.argv) > 1:
        traverse_directory(sys.argv[1])
    else:
        print("没有提供命令行参数")

if __name__ == "__main__":
    main()



