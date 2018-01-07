# Home-Assistant Bluetooth Scan for Docker

使用 `hcitool name $MAC` 方法来查询设备是否在家，如在家则通过 Rest_API 更新 device_tracker 的 location_name( home | not_home )。

# 先决条件

运行 docker 的设备必须驱动了蓝牙，能够正常使用蓝牙。

# 安装

## 第一步：编辑 Home-Assistant 的 known_devices.yaml 文件

格式如下：

```
mi3xiaomishouji:
  hide_if_away: false
  icon:
  mac: C4:6A:B7:C5:DD:BF
  name: MI3-xiaomishouji
  picture:
  track: true
  vendor: unknown
```
对于我们来说，只需要编写三个地方。

* **mi3xiaomishouji**:这个是 Home Assistant device_tracker 的设备ID，必须为英文。
* **mac**:此处编写需要跟踪设备的蓝牙mac，注意是蓝牙的mac，不是wifi的mac。
* **track**:此选项控制是否跟踪此设备，如果不需要跟踪则设为 false。

参考自：[https://home-assistant.io/components/device_tracker/](https://home-assistant.io/components/device_tracker/) known_devices.yaml 部分。

## 第二步：运行 image

```
docker run --rm \
--net=host \
--name bluetooth_scan \
-e HA_API_PASSWD="home-assistant_rest_api_passwd" \
-e HA_URL="https://home-assistant_url" \
-e SLEEP_NUM=2
-v /usr/share/hassio/homeassistant/known_devices.yaml:/known_devices.yaml \
-itd neroxps/bluetooth_scan_track
```
* **HA_API_PASSWD（必须）**:输入 homeassistant API 密码
* **HA_URL（必须）**:输入 homeassistant 网址，格式为 [ http://home.domain.com | https://home.domain.com | http://ip:8123 ]
* **known_devices.yaml（必须）**:使用 -v 参数映射 Home Assistant 的 known_devices.yaml 文件。
* **--net=host**:使用主机模式运行，容器才能使用蓝牙设备。
* **SLEEP_NUM(可选)**:此参数控制扫描的间隔，单位为秒。（默认是2秒）


# 副作用

* 因为是使用 REST_API 更新状态，所以会导致 IOS 和 Android 利用 REST_API 更新设备地理位置被覆盖，导致无法进行地理位置跟踪。
* 此方法需要一直占用蓝牙适配器，导致服务器的其他蓝牙服务无法使用。
* 有可能会影响手机的蓝牙连接（具体需要观察才知道是否有影响）