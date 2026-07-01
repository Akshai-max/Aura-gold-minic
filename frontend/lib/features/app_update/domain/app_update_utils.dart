bool isAppUpdateAvailable({
  required int currentVersionCode,
  required int remoteVersionCode,
}) {
  return remoteVersionCode > currentVersionCode;
}
