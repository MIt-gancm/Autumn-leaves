import requests  ###pip install requests
import os
import time

nc="\033[0m"     ###无色
red="\033[31m"    ###红色
green="\033[32m"    ###绿色

os.system("clear")

print(f"{green}--------------开始测速--------------{nc}")

url_list=["https://mirrors.nju.edu.cn","https://mirrors.aliyun.com","https://mirrors.tuna.tsinghua.edu.cn","https://mirrors.ustc.edu.cn"]

def get_file_size(url):
    try:
        response = requests.head(f"{url}/ubuntu/ls-lR.gz", allow_redirects=True, timeout=5)
        if response.status_code == 200 and 'Content-Length' in response.headers:
            return int(response.headers['Content-Length'])
    except Exception:
        return None

os.chdir(os.path.expanduser("~/.gancm/download"))
times=0

order=[]

for url in url_list:
    times+=1
    print(f"{green}\n==========第{times}次测试，链接{url}=========={nc}")
    size=get_file_size(url)
    if size is None:
        print(f"{red}{url}拒绝了连接！(悲){nc}")
        time.sleep(2)
        continue
    start=time.time()
    os.system(f"wget {url}/ubuntu/ls-lR.gz")
    end=time.time()
    start_end=end-start
    speed=size/start_end/1024/1024
    print(f"下载链接：{url}\n速度：{speed:.2f}MB/s")
    order.append((speed,url))
    time.sleep(2)
    os.system("rm -rf *")

order_sorted = sorted(order, key=lambda x: x[0], reverse=True)
fastest=order_sorted[0]
fastest_url=fastest[1]

os.system("clear")
print(f"{green}测试完成！（完全胜利）{nc}")
print(f"{green}目前下载最快镜像源：{fastest_url}\n速度：{fastest[0]:.2f}MB/s{nc}")

reply1=input("是否替换？[Y/n]")

if reply1 in ["","Y","y"]:
    print(f"{green}选择替换\n{nc}")
    time.sleep(1)
    if fastest_url == "https://mirrors.aliyun.com":
        reply2=input("真的要换为清华源吗(傻逼清华源有时候概率存在部分问题)[Y/n]")
        if reply2 in ["","Y","y"]:
            os.system("sed -i 's@^\\(deb.*stable main\\)$@#\\1\\ndeb https://mirrors.aliyun.com/termux/termux-packages-24 stable main@' $PREFIX/etc/apt/sources.list && pkg up")
        else:
            print(f"{red}取消\n{nc}")
            time.sleep(1)
            os.system("bash ~/.gancm/gancm.sh")   ###重新开启脚本
    if fastest_url == "https://mirrors.ustc.edu.cn":
        os.system("sed -i 's@^\\(deb.*stable main\\)$@#\\1\\ndeb https://mirrors.ustc.edu.cn/termux stable main@' $PREFIX/etc/apt/sources.list && pkg up")
    if fastest_url == "https://mirrors.nju.edu.cn":
        os.system("sed -i 's@^\\(deb.*stable main\\)$@#\\1\\ndeb https://mirrors.nju.edu.cn/termux/apt/termux-main stable main@' $PREFIX/etc/apt/sources.list && pkg up")
    if fastest_url == "https://mirrors.tuna.tsinghua.edu.cn":
        os.system("sed -i 's@^\\(deb.*stable main\\)$@#\\1\\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 stable main@' $PREFIX/etc/apt/sources.list && pkg up")
else:
    print(f"{red}选择取消\n{nc}")
    print("流量：我免费力！\n不要浪费时间哦。。。")
    time.sleep(1)
os.system("bash ~/.gancm/gancm.sh")   ###重新开启脚本