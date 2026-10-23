module.exports = {
  apps: [
    {
      name: "uxplay",
      script: "/usr/bin/uxplay",
      args: "-s 800x480 -v4l2 -bt709 -vs waylandsink",
      env: {
        WAYLAND_DISPLAY: "wayland-0",
        XDG_RUNTIME_DIR: "/run/user/1000"
      }
    }
  ]
};