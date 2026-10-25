# Container Manager 프로젝트를 DSM API(SYNO.Docker.Project)로 다루는 도우미, NAS에서 실행함
#   python3 synoproj.py list
#   python3 synoproj.py <get|start|stop|restart|build_stream|delete> <프로젝트>
#   python3 synoproj.py create <프로젝트> <compose 파일> [docker 폴더 기준 경로]
#   python3 synoproj.py update <프로젝트> <compose 파일>
# PC에서는 ssh로 보내 실행함: ssh SiLENT_NAS 'python3 - list' < synoproj.py
import json
import subprocess
import sys
import time

SYNOWEBAPI = "/usr/syno/bin/synowebapi"


def call(method, **params):
    """API를 호출하고 (출력 마지막 JSON, 전체 출력)을 돌려줌"""
    args = ["sudo", "-n", SYNOWEBAPI, "--exec", "api=SYNO.Docker.Project",
            f"method={method}", "version=1"]
    # 인자 값은 JSON으로 넘겨야 함 (문자열도 따옴표 포함)
    args += [f"{key}={json.dumps(value)}" for key, value in params.items()]
    out = subprocess.run(args, capture_output=True, text=True).stdout
    # *_stream 동작은 진행 로그 뒤에 JSON이 오므로 마지막 JSON만 읽음
    start = out.rfind("\n{")
    start = start + 1 if start >= 0 else out.find("{")
    if start < 0:
        return {}, out
    return json.loads(out[start:]), out


def projects():
    result, out = call("list")
    if not result.get("success"):
        sys.exit(f"Project list failed: {out[-500:]}")
    return result["data"]


def project_id(name):
    for pid, project in projects().items():
        if project["name"] == name:
            return pid
    return None


def state(pid):
    data = call("get", id=pid)[0].get("data", {})
    containers = [(c.get("Name", "").lstrip("/"),
                   c.get("State", {}).get("Status"))
                  for c in data.get("containers") or []]
    return data.get("status"), containers


def main():
    if len(sys.argv) < 2:
        sys.exit("Usage: synoproj.py <method> [project] [compose file]")
    method = sys.argv[1]
    if method == "list":
        for p in sorted(projects().values(), key=lambda p: p["name"]):
            print(f"{p['name']:22} {p['status']:9} {p['path']}")
        return

    name = sys.argv[2]
    pid = project_id(name)
    if method != "create" and not pid:
        sys.exit(f"Project not found: {name}")

    if method == "create":
        # 프로젝트 폴더는 먼저 만들어 둬야 함
        # 기본은 /volume1/docker/<이름>, HA 하위 프로젝트처럼 다르면 경로를 줌
        # (예: home-assistant/eclipse-mosquitto)
        content = open(sys.argv[3]).read()
        folder = sys.argv[4] if len(sys.argv) > 4 else name
        result, out = call("create", name=name,
                           share_path=f"/docker/{folder}", content=content,
                           enable_service_portal=False,
                           service_portal_name="", service_portal_port=0,
                           service_portal_protocol="")
        pid = (result.get("data") or {}).get("id")
    elif method == "update":
        result, out = call("update", id=pid, content=open(sys.argv[3]).read())
    elif method == "get":
        print(call("get", id=pid)[0].get("data", {}).get("content", ""))
        return
    else:
        result, out = call(method, id=pid)

    # 상태가 반영될 시간을 잠깐 기다림
    time.sleep(4)
    current = state(pid) if pid and method != "delete" else None
    print(f"{name} {method}: success={result.get('success')} "
          f"error={result.get('error')} -> {current}")
    if not result.get("success") or method.endswith("_stream"):
        print(out[-2000:])
    if not result.get("success"):
        sys.exit(1)


if __name__ == "__main__":
    main()
