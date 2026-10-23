const os = require("os");

function getLocalIpAddress() {
    const interfaces = os.networkInterfaces();
    
    // 1순위: 192.168.x.x 대역의 실제 IPv4 주소 탐색
    for (const name of Object.keys(interfaces)) {
        for (const net of interfaces[name]) {
            if (net.family === "IPv4" && !net.internal) {
                if (net.address.startsWith("192.168.")) {
                    return net.address;
                }
            }
        }
    }

    // 2순위: 192.168 대역을 못 찾은 경우 Docker 가상 IP(172.19.x.x 등) 제외하고 탐색
    for (const name of Object.keys(interfaces)) {
        for (const net of interfaces[name]) {
            if (net.family === "IPv4" && !net.internal) {
                // Docker 기본 가상 브릿지 및 루프백 제외
                if (!net.address.startsWith("172.19.") && !net.address.startsWith("127.")) {
                    return net.address;
                }
            }
        }
    }

    return "0.0.0.0";
}

let config = {
    // address: "localhost",
    // address: "0.0.0.0",
    address: getLocalIpAddress(),
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
        { 
            module: "MMM-mmpm",
        },
        {
            module: 'MMM-page-indicator',
            position: 'bottom_bar',
            config: {
                activeBright: true,
            }
        },

        {
            module: "helloworld",
            position: "middle_center",
            classes: "screen_saver_text",
            config: {
                text: "screen_saver_text"
            }
        },

        {
            module: 'MMM-Remote-Control',
            position: 'middle_center', // Required to show URL/QR code on mirror
            // you can hide this module afterwards from the remote control itself
            config: {
                customCommand: {},  // Optional, See "Using Custom Commands" below
                secureEndpoints: true, // Optional, See API/README.md
                // uncomment any of the lines below if you're gonna use it
                // customMenu: "custom_menu.json", // Optional, See "Custom Menu Items" below
                // apiKey: "", // Optional, See API/README.md for details
                // classes: {}, // Optional, See "Custom Classes" below
                // showModuleApiMenu: false, // Optional, disable the Module Controls menu
                // showNotificationMenu: false, // Optional, disable the Notification menu

                // QR Code options (new!)
                // showQRCode: true, // Optional, display QR code for easy mobile access (default: true)
                // qrCodeSize: 150, // Optional, size of QR code in pixels (default: 150)
                // qrCodePosition: "below" // Optional:
                //   "below" - Show URL above, QR code below (default)
                //   "above" - Show QR code above, URL below
                //   "replace" - Show only QR code, no URL text
            }
        },

        {
            module: 'MMM-OnScreenMenu',
            position: 'bottom_right',
            /* Valid positions: 'top_right', 'top_left', 'bottom_right', 'bottom_left' */
            config: {
                touchMode: true,
                enableKeyboard: true,
                // ... see more options below
            }
        },

        {
            module: 'MMM-SmartTouch', 
            position: 'bottom_center',    // This can be any of the regions.(bottom-center Recommended)
            config:{ 
                // None configuration options defined 
            }
        },
        
        {
            module: "MMM-pages",
            config: {
                timings: {
                    default: 2000,               // rotate every 5 seconds
                    // 0: 5000,                    // page 0 rotates every 20 seconds
                    // "admin": 30000               // admin hidden page auto-returns after 30 seconds
			    },
                modules: [
                    ["title_current_time", "flipclock"],
                    ["title_today_current_weather", "today_current_weather"],
                    ["title_today_hourly_forecast_weather", "today_hourly_forecast_weather"],
                    ["title_daily_forecast_weather", "daily_forecast_weather"],

                ],
                fixed: [                         // modules that are always shown
                    "MMM-pages",
                    "MMM-page-indicator",
                ],
                hiddenPages: {                   // modules that are only shown on specific pages
                    "screenSaver": [
                        "screen_saver_text",
                    ],
                    "admin": [
                        "MMM-Remote-Control",
                        "MMM-OnScreenMenu",
                        "MMM-SmartTouch"
                    ]
                }
            },
        },

        {
            module: "helloworld",
            position: "top_bar",
            classes: "title_current_time",
            config: {
                text: "current_time"
            }
        },
        {
            module: "MMM-FlipClock",
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
            }
        },

        {
            module: "helloworld",
            position: "top_bar",
            classes: "title_today_current_weather",
            config: {
                text: "today_current_weather"
            }
        },
		{
			module: "weather",
			classes: "today_current_weather",
			position: "middle_center",
			config: {
				weatherProvider: "openmeteo",
				type: "current",
				lat: 0,
				lon: 0,
				degreeLabel: true,
				showHumidity: "temp",
				showUVIndex: true,
				showPrecipitationProbability: true,
			}
		},
        
        {
            module: "helloworld",
            position: "top_bar",
            classes: "title_today_hourly_forecast_weather",
            config: {
                text: "today_hourly_forecast_weather"
            }
        },
		{
			module: "weather",
			classes: "today_hourly_forecast_weather",
			position: "middle_center",
			config: {
				weatherProvider: "openmeteo",
				type: "hourly",
				lat: 0,
				lon: 0,
			}
		},

        {
            module: "helloworld",
            position: "top_bar",
            classes: "title_daily_forecast_weather",
            config: {
                text: "daily_forecast_weather"
            }
        },
		{
			module: "weather",
			classes: "daily_forecast_weather",
			position: "middle_center",
			config: {
				weatherProvider: "openmeteo",
				type: "forecast",
				lat: 0,
				lon: 0,
				colored: true,
				tableClass: "small",
			}
		},

    ]
};


/*************** DO NOT EDIT THE LINE BELOW ***************/
if (typeof module !== "undefined") {
    module.exports = config;
}