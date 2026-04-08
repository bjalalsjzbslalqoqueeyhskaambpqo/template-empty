local appName = "Disaster"
local appPackage = "com.gametool.disaster"

local Solar2DPath = arg and arg[0] and arg[0]:match("(.*/)") or "./"
package.path = Solar2DPath .. "?.lua;" .. package.path

local buildParams = {
    appName = appName,
    appPackage = appPackage,
    versionCode = 1,
    versionName = "1.0",
    projectPath = "./Project",
    outputPath = "./Build",
    keystorePath = "./Util/android.keystore",
    keystorePassword = "android",
    keystoreAlias = "androiddebugkey",
    aliasPassword = "android",
    targetPlatform = "android",
    debugBuild = true,
}

os.execute("mkdir -p Build")

local cmd = string.format(
    'CoronaBuilder build --android' ..
    ' --appname "%s"' ..
    ' --package "%s"' ..
    ' --project "%s"' ..
    ' --output "%s"' ..
    ' --keystore "%s"' ..
    ' --storepass "%s"' ..
    ' --alias "%s"' ..
    ' --aliaspass "%s"',
    buildParams.appName,
    buildParams.appPackage,
    buildParams.projectPath,
    buildParams.outputPath,
    buildParams.keystorePath,
    buildParams.keystorePassword,
    buildParams.keystoreAlias,
    buildParams.aliasPassword
)

print("Building: " .. cmd)
local result = os.execute(cmd)
if result ~= 0 then
    print("Build failed!")
    os.exit(1)
end
print("Build successful!")
