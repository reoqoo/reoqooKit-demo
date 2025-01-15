# reoqooKit 1.0.10 Update Note

### RQWebService
bugfixed:
1. Hide `close`, `menu` button which are on navigation bar by default.
2. `appName`, `pkgName` have to transfer to our H5 web view.
3. The back item on navigation bar is useful when web view is being modal displaying.  

### RQApi
new:
1. Add device `turn on` `turn off` api
bugfixed:
1. When request the device new version info, the language of description is not correct

### RQDeviceAddition
new:
1. Remove the SDK `RxSwift`

### RQCore
new:
1. Remove the SDK `RxSwift`. So `RxSwift` is not required for reoqooKit now. (But for demo, `RxSwift` is still required)
bugfixed:
1. Open the `My transaction` web view meet 404.
2. fixed bugs which are founding by our testing department.
