cask "yuclash" do
  version "VERSION"

  on_macos do
    arch arm: "arm64", intel: "amd64"

    sha256 arm:   "ARM_SHA256",
           intel: "AMD_SHA256"

    url "https://github.com/Little-Orange-Limited/YuClash/releases/download/v#{version}/YuClash-#{version}-macos-#{arch}.dmg"
  end

  name "YuClash"
  desc "Multi-platform proxy client based on ClashMeta"
  homepage "https://github.com/Little-Orange-Limited/YuClash"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "YuClash.app"

  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-rd", "com.apple.quarantine", "{{appdir}}/YuClash.app"],
        writable_paths: ["YuClash.app"],
        writable_base:  :appdir
  end

  uninstall quit: "com.yucloud.clash"

  zap trash: [
    "~/Library/Application Support/com.yucloud.clash",
    "~/Library/Caches/com.yucloud.clash",
    "~/Library/Preferences/com.yucloud.clash.plist",
    "~/Library/Saved Application State/com.yucloud.clash.savedState",
  ]
end
