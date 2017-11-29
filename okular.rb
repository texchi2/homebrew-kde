class Okular < Formula
  desc "Document Viewer"
  homepage "https://okular.kde.org"
  url "https://download.kde.org/stable/applications/17.08.3/src/okular-17.08.3.tar.xz"
  sha256 "d32e69b6be2a10d0eadc6f616be53dc8dd372c9123a6311628ac3f97b69054fd"
  revision 1

  head "git://anongit.kde.org/okular.git"

  depends_on "cmake" => :build
  depends_on "KDE-mac/kde/kf5-extra-cmake-modules" => :build
  depends_on "KDE-mac/kde/kf5-kdoctools" => :build

  depends_on "chmlib" => :optional
  depends_on "ebook-tools" => :optional
  depends_on "KDE-mac/kde/kf5-khtml" => :optional
  depends_on "KDE-mac/kde/kf5-kirigami2" => :optional

  depends_on "qca"
  depends_on "zlib"
  depends_on "freetype"
  depends_on "libspectre"
  depends_on "djvulibre"
  depends_on "poppler" => "with-qt"
  depends_on "KDE-mac/kde/kf5-breeze-icons"
  depends_on "KDE-mac/kde/kf5-kactivities"
  depends_on "KDE-mac/kde/kf5-kjs"
  depends_on "KDE-mac/kde/kf5-kparts"
  depends_on "KDE-mac/kde/kf5-kpty"
  depends_on "KDE-mac/kde/kf5-threadweaver"
  depends_on "KDE-mac/kde/libkexiv2"

  patch do
    url "https://raw.githubusercontent.com/RJVB/macstrop/master/kf5/kf5-okular/files/patch-plugin-depends.diff"
    sha256 "33e5e0fa2a10fea2f11a1b975bfee3d87d80215aedb8013ea2d318818a250a46"
  end
  patch :DATA

  stable do
    patch do
      url "https://phabricator.kde.org/file/data/2wvots3vggm53vjkm72r/PHID-FILE-ttv6g4vnc65feqzauhm4/file"
      sha256 "702b39e7d2d2c471dea9fa55a46420f26c286df929823cab374fc25264a76d58"
    end
  end

  def install
    args = std_cmake_args
    args << "-DBUILD_TESTING=OFF"
    args << "-DKDE_INSTALL_QMLDIR=lib/qt5/qml"
    args << "-DKDE_INSTALL_PLUGINDIR=lib/qt5/plugins"
    args << "-DCMAKE_INSTALL_BUNDLEDIR=#{bin}"

    mkdir "build" do
      system "cmake", "..", *args
      system "make", "install"
      prefix.install "install_manifest.txt"
    end
    # Extract Qt plugin path
    qtpp = `#{Formula["qt"].bin}/qtpaths --plugin-dir`.chomp
    system "/usr/libexec/PlistBuddy",
      "-c", "Add :LSEnvironment:QT_PLUGIN_PATH string \"#{qtpp}\:#{HOMEBREW_PREFIX}/lib/qt5/plugins\"",
      "#{bin}/okular.app/Contents/Info.plist"
  end

  def post_install
    ln_sf HOMEBREW_PREFIX/"share/icons/breeze/breeze-icons.rcc", HOMEBREW_PREFIX/"share/okular/icontheme.rcc"
  end

  def caveats; <<-EOS.undent
    You need to take some manual steps in order to make this formula work:
      ln -sf "$(brew --prefix)/share/okular" "$HOME/Library/Application Support"
      ln -sf "$(brew --prefix)/share/kconf_update" "$HOME/Library/Application Support"
      ln -sf "$(brew --prefix)/share/config.kcfg" "$HOME/Library/Application Support"
      ln -sf "$(brew --prefix)/share/kservices5" "$HOME/Library/Application Support"
      ln -sf "$(brew --prefix)/share/kservicetypes5" "$HOME/Library/Application Support"
      ln -sf "$(brew --prefix)/share/kxmlgui5" "$HOME/Library/Application Support"
      ln -sf "$(brew --prefix)/share/metainfo" "$HOME/Library/Application Support"
      mkdir -p $HOME/Applications/KDE
      ln -sf "#{prefix}/bin/okular.app" $HOME/Applications/KDE/
    EOS
  end
end

__END__
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 7537220..5fef3d7 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -190,7 +190,7 @@ generate_export_header(okularcore BASE_NAME okularcore EXPORT_FILE_NAME "${CMAKE

 # Special handling for linking okularcore on OSX/Apple
 IF(APPLE)
-    SET(OKULAR_IOKIT "-framework IOKit" CACHE STRING "Apple IOKit framework")
+    SET(OKULAR_IOKIT "-framework CoreFoundation -framework CoreGraphics -framework IOKit" CACHE STRING "Apple IOKit framework")
 ENDIF(APPLE)

 target_link_libraries(okularcore
diff --git a/core/utils.cpp b/core/utils.cpp
index c9bfc2d..b8c955f 100644
--- a/core/utils.cpp
+++ b/core/utils.cpp
@@ -134,7 +134,7 @@ QSizeF Utils::realDpi(QWidget* widgetOnScreen)
         return err;
     }

-double Utils::realDpiX()
+static double realDpiX()
 {
     double x,y;
     CGDisplayErr err = GetDisplayDPI( CGDisplayCurrentMode(kCGDirectMainDisplay),
@@ -144,7 +144,7 @@ double Utils::realDpiX()
     return err == CGDisplayNoErr ? x : 72.0;
 }

-double Utils::realDpiY()
+static double realDpiY()
 {
     double x,y;
     CGDisplayErr err = GetDisplayDPI( CGDisplayCurrentMode(kCGDirectMainDisplay),
