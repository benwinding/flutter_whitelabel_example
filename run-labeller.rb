#!/usr/bin/env ruby

require "fileutils"
require "json"
require "nokogiri"

def processConfiguration(configDir)
  puts "--- processing: #{configDir}"
  outWhitelabelDir = "./builds/app-release-" + configDir
  if (!File.directory?(outWhitelabelDir))
    puts "---- Making whitelabel folder: #{outWhitelabelDir}"
    FileUtils.mkdir_p(outWhitelabelDir)
    outDir = "./builds/app-release/."
    FileUtils.cp_r(outDir, outWhitelabelDir)
  end
  configData = getValidConfig(configDir)
  updateManifest(configData, outWhitelabelDir)
  shrinkImages(configDir)
  copyImages(configDir, outWhitelabelDir)
  makeLabelApk(outWhitelabelDir, configDir)
  signLabelApk(outWhitelabelDir, configDir)
  FileUtils.rm_r(outWhitelabelDir)
end

def resizeSingleImage(src, dest, w)
  destDir = File.dirname(dest)
  if !File.directory?(destDir)
    FileUtils.mkdir_p(destDir)
  end
  system("convert " + src + " -resize " + w.to_s + "x" + w.to_s + " " + dest)
end

def shrinkImages(configDir)
  imageSrc = "labels/" + configDir + "/ic_launcher.png"
  destDir = "labels/" + configDir + "/_res_generated/"
  imName = "ic_launcher.png"
  puts "---- resizing mipmaps: " + imageSrc + " (72, 48, 96, 144, 192)"
  resizeSingleImage(imageSrc, destDir + "mipmap-hdpi/" + imName, 72)
  resizeSingleImage(imageSrc, destDir + "mipmap-mdpi/" + imName, 48)
  resizeSingleImage(imageSrc, destDir + "mipmap-xhdpi/" + imName, 96)
  resizeSingleImage(imageSrc, destDir + "mipmap-xxhdpi/" + imName, 144)
  resizeSingleImage(imageSrc, destDir + "mipmap-xxxhdpi/" + imName, 192)
end

def copyImages(configDir, outWhitelabelDir)
  srcDir = "labels/" + configDir + "/_res_generated/."
  destDir = outWhitelabelDir + "/res"
  puts "---- replacing images"
  FileUtils.cp_r(srcDir, destDir)
end

def makeLabelApk(outWhitelabelDir, configName)
  whitelabelApkPath = "./builds/app-release-" + configName + ".apk"
  puts "---- Building APK: " + whitelabelApkPath
  if File.file?(whitelabelApkPath)
    FileUtils.rm(whitelabelApkPath)
  end
  system("apktool b " + outWhitelabelDir + " -o " + whitelabelApkPath)
end

def signLabelApk(outWhitelabelDir, configName)
  whitelabelApkPath = "./builds/app-release-" + configName + ".apk"
  keyPath = "labels/" + configName + "/my-release-key.keystore"
  puts "---- Signing APK: " + whitelabelApkPath
  system("jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore " + keyPath + " " + whitelabelApkPath + " alias_name -storepass aaaaaa")
end

def updateManifest(configData, outWhitelabelDir)
  manifestPath = outWhitelabelDir + "/AndroidManifest.xml"
  @doc = Nokogiri::XML(File.open(manifestPath))

  puts "---- manifest: updating package: " + configData["package"]
  @doc.xpath("/manifest").first["package"] = configData["package"]

  puts "---- manifest: updating android:label: " + configData["android:label"]
  @doc.xpath("//application").first["android:label"] = configData["android:label"]
  puts "---- manifest: writing to file"

  File.write(manifestPath, @doc.to_s)
end

def checkHas(obj, fieldName, pathWhere)
  if !obj[fieldName]
    raise 'Missing field "' + fieldName + '" in ' + pathWhere
  end
end

def getValidConfig(configDir)
  configPath = "./labels/" + configDir + "/config.json"
  configText = File.read(configPath)
  configData = JSON.parse(configText)
  puts "---- reading config json: " + configPath
  checkHas(configData, "package", configPath)
  checkHas(configData, "name", configPath)
  checkHas(configData, "android:label", configPath)
  return configData
end

def ProcessConfigs()
  Dir.entries("./labels").sort.each do |configDir|
    next if configDir == "." or configDir == ".."
    processConfiguration(configDir)
  end
end

def Setup()
  outDir = "./builds/app-release"
  buildFile = "./builds/app-release.apk"
  FileUtils.mkdir_p('./builds')
  if !File.file?(buildFile)
    appBuildFile = "./app/build/app/outputs/flutter-apk/app-release.apk"
    if !File.file?(appBuildFile)
      raise "The app needs to be built first, could not find the file: " + appBuildFile
    end
    FileUtils.cp(appBuildFile, buildFile)
  end
  if !File.directory?(outDir)
    puts "Decompressing app-release.apk"
    system("apktool d " + buildFile + " -o " + outDir)
  end
end

Setup()
ProcessConfigs()
