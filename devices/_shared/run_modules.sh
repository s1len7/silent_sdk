#!/usr/bin/env bash
# setup 진입점이 source해서 run_modules로 모듈을 순서대로 실행하는 공통 함수
# - 모듈이 실패해도 다음 모듈을 계속 실행하고, 끝에 모듈별 결과(OK / SKIP / FAIL)를 요약함
# - 모듈은 이미 설정돼 있으면 종료 코드 3으로 끝나며 SKIP으로 표시됨
# - run_modules <device_dir> <modules_dir> <summary_width> <entry...>
#   entry에 '/'가 있으면 <device_dir>/<entry>.sh (예: pi5가 pi4-display 공통 모듈을 쓸 때)
#   없으면 <device_dir>/<modules_dir>/<entry>.sh
# - 실행 후 run_failed(실패 수), run_skipped(SKIP 수)를 남김 (진입점이 재부팅 판단 등에 사용)
run_modules() {
    local device_dir="$1" modules_dir="$2" width="$3"
    shift 3
    local summary=() failed=0 skipped=0 entry name module code result start
    for entry in "$@"; do
        if [[ "$entry" == */* ]]; then
            name="$(basename "$entry")"
            module="$device_dir/$entry.sh"
        else
            name="$entry"
            module="$device_dir/$modules_dir/$entry.sh"
        fi
        echo
        echo "=== [$name] started $(date +%H:%M:%S)"
        start=$SECONDS
        if [[ -f "$module" ]]; then
            bash "$module"
            code=$?
        else
            echo "Module not found: $module" >&2
            code=127
        fi
        case $code in
            0) result=OK ;;
            3) result=SKIP; skipped=$((skipped + 1)) ;;
            *) result="FAIL (exit $code)"; failed=$((failed + 1)) ;;
        esac
        echo "=== [$name] $result ($((SECONDS - start))s)"
        summary+=("$(printf '%-*s %s' "$width" "$name" "$result")")
    done

    echo
    echo "=== Summary"
    printf '%s\n' "${summary[@]}"
    if (( failed )); then
        echo "$failed of ${#summary[@]} modules failed. See the log, then run the setup again (finished modules are skipped)."
    else
        echo "All ${#summary[@]} modules succeeded or were already set up."
    fi
    echo "Log: $log_dir/setup.log"

    run_failed=$failed
    run_skipped=$skipped
}
