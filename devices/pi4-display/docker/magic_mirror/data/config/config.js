// 날씨 위치는 docker/magic_mirror/.env의 MM_LAT, MM_LON에서 읽음 (저장소에 좌표를 남기지 않기 위함)
const weatherLat = parseFloat(process.env.MM_LAT);
const weatherLon = parseFloat(process.env.MM_LON);
if (!Number.isFinite(weatherLat) || !Number.isFinite(weatherLon)) {
    throw new Error("MM_LAT and MM_LON must be set in docker/magic_mirror/.env");
}

let config = {
    // 모든 인터페이스에 바인딩 (localhost와 LAN IP 모두 응답)
    // 기기 IP에만 바인딩하면 이미지의 헬스체크(127.0.0.1:8080)가 실패해 unhealthy로 표시됨
    address: "0.0.0.0",
    port: 8080,

    basePath: "/",

    ipWhitelist: [],

    language: "ko",
    locale: "ko-KR",

    // timeFormat: 24,
    timeFormat: 12,
    units: "metric",

    electronOptions: {
        webPreferences: {
            webviewTag: true
        }
    },

    // https://docs.magicmirror.builders/modules/introduction.html
    modules: [
        // MMPM 웹UI에서 모듈 표시/숨김을 제어하기 위한 동반 모듈 (화면에는 아무것도 표시하지 않음)
        {
            module: "MMM-mmpm",
        },

        // 800x480 화면에 한 페이지씩만 표시하고 2초마다 넘김
        {
            module: "MMM-pages",
            config: {
                timings: {
                    default: 5000,
                    // 숨김 페이지는 30초 뒤 자동으로 돌아옴 (MMM-pages는 숨김 페이지에만 timings.<이름> 사용)
                    admin: 30000,
                },
                modules: [
                    ["flipclock"],
                    ["today_current_weather"],
                    ["today_hourly_forecast_weather"],
                    ["daily_forecast_weather"],
                ],
                fixed: [                         // modules that are always shown
                    "MMM-pages",
                    "MMM-page-indicator",
                    "MMM-Modulebar",
                    "MMM-TouchButton",
                ],
                hiddenPages: {                   // modules that are only shown on specific pages
                    "admin": [
                        "MMM-Remote-Control",
                        "MMM-TouchButton",
                    ],
                },
            },
        },

        {
            module: "MMM-page-indicator",
            position: "bottom_bar",
            config: {
                activeBright: true,
            },
        },

        // 화면을 터치해 모든 모듈을 가리거나 되돌림 (대기모드)
        // MMM-SmartTouch, MMM-OnScreenMenu(모두 유지보수 중지)를 대체
        {
            module: "MMM-Modulebar",
            position: "bottom_left",
            config: {
                showBorder: false,
                direction: "row",
                buttons: {
                    "1": {
                        module: "all",
                        symbol: "eye",
                        symbol2: "eye-slash",
                        size: 2,
                    },
                },
            },
        },

        // 관리자(웹 리모컨 QR) 숨김 페이지를 열고 닫는 터치 버튼
        // MMM-pages의 hiddenPages는 알림으로만 열 수 있어 화면에 진입 버튼이 필요함
        {
            module: "MMM-TouchButton",
            position: "bottom_right",
            config: {
                buttons: [
                    {
                        name: "admin",
                        icon: "fa fa-qrcode",
                        notification: "SHOW_HIDDEN_PAGE",
                        payload: "admin",
                    },
                    {
                        name: "leave",
                        icon: "fa fa-undo",
                        notification: "LEAVE_HIDDEN_PAGE",
                    },
                ],
            },
        },

        // 관리자 페이지에서만 표시 (웹 리모컨 접속 URL/QR 코드)
        {
            module: "MMM-Remote-Control",
            header: "관리자 (웹 리모컨)",
            position: "middle_center",
            config: {
                secureEndpoints: true,
                qrCodeSize: 200,
            },
        },

        {
            module: "MMM-FlipClock",
            header: "시간",
            classes: "flipclock",
            position: "middle_center",
            config: {
                dateFormat: "YYYY/MM/DD",
                // timeFormat: 12,
                showPeriod: false,
                // showPeriodUpper: true,
                displaySeconds: false,
                showDate: true,
                timezone: "Asia/Seoul",
                // showWeek: true,
            },
        },

        {
            module: "weather",
            header: "현재 날씨",
            classes: "today_current_weather",
            position: "middle_center",
            config: {
                weatherProvider: "openmeteo",
                type: "current",
                lat: weatherLat,
                lon: weatherLon,
                degreeLabel: true,
                showHumidity: "temp",
                showUVIndex: true,
                showPrecipitationProbability: true,
            },
        },

        {
            module: "weather",
            header: "시간별 예보",
            classes: "today_hourly_forecast_weather",
            position: "middle_center",
            config: {
                weatherProvider: "openmeteo",
                type: "hourly",
                lat: weatherLat,
                lon: weatherLon,
                // MagicMirror 기본값은 5개. 800x480 높이에 8개까지 들어감
                maxEntries: 8,
                // 시간대별 강수 확률 표시 (비 올 시간을 미리 알 수 있게)
                showPrecipitationProbability: true,
            },
        },

        {
            module: "weather",
            header: "주간 예보",
            classes: "daily_forecast_weather",
            position: "middle_center",
            config: {
                weatherProvider: "openmeteo",
                type: "forecast",
                lat: weatherLat,
                lon: weatherLon,
                // MagicMirror 기본값은 5일. "주간 예보" 제목에 맞춰 7일 표시
                // (forecast 템플릿은 maxEntries가 아니라 maxNumberOfDays를 씀)
                maxNumberOfDays: 7,
                colored: true,
                tableClass: "small",
            },
        },

    ]
};


/*************** DO NOT EDIT THE LINE BELOW ***************/
if (typeof module !== "undefined") {
    module.exports = config;
}
