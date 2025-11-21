#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEScan.h>
#include <BLEAdvertisedDevice.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "esp_bt.h"
#include "esp_bt_main.h"

#define ENABLE_FILTER true

const String FILTER_KEYWORDS[] = {"key", "beacon", "nrf52", "mydevice"};
const int NUM_KEYWORDS = 4;

// WiFi credentials
const char* ssid = "Mert";
const char* password = "korab@minava";

// HiveMQ Cloud MQTT settings
const char* mqtt_server = "f9abd57dbad2404abb6a7cc90b2960e1.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;
const char* mqtt_username = "PMGonTOPVTOM";
const char* mqtt_password = "Aposiopeza...67";
const char* device_id = "esp32_001";

// MQTT Topics
char topic_commands[100];
char topic_results[100];
char topic_status[100];

// Pin definitions
#define WIFI_LED_PIN 34
#define MQTT_LED_PIN 35

// BLE settings
#define SCAN_TIME 2
#define SCAN_INTERVAL 4000
#define DEVICE_TIMEOUT 10000

BLEScan* pBLEScan;
WiFiClientSecure espClient;
PubSubClient mqttClient(espClient);

// Structure to store device info: TODO: optimization maybe
struct BLEDeviceInfo {
  String name;
  String address;
  int rssi;
  unsigned long lastSeen;
  bool active;
};

// Reduced array size for memory: Core 0 error
const int MAX_DEVICES = 10;
BLEDeviceInfo devices[MAX_DEVICES];
int deviceCount = 0;
int totalScanned = 0;
int filteredOut = 0;

// MQTT connection tracking
unsigned long lastMqttAttempt = 0;
const long mqttRetryInterval = 10000;
bool mqttConnected = false;
bool bleActive = false;

// Forward declarations
void updateDevice(String name, String address, int rssi);
void mqttCallback(char* topic, byte* payload, unsigned int length);
void reconnectMQTT();
void performScanAndPublish(String requestId);
void publishStatus();
bool matchesFilter(String name, String address);

String toLowerCase(String str) {
  String result = str;
  result.toLowerCase();
  return result;
}

bool matchesFilter(String name, String address) {
  if (!ENABLE_FILTER) return true;
  
  String nameLower = toLowerCase(name);
  String addressLower = toLowerCase(address);
  
  for (int i = 0; i < NUM_KEYWORDS; i++) {
    String keyword = toLowerCase(FILTER_KEYWORDS[i]);
    if (nameLower.indexOf(keyword) >= 0 || addressLower.indexOf(keyword) >= 0) {
      return true;
    }
  }
  return false;
}

class MyAdvertisedDeviceCallbacks: public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice advertisedDevice) {
    totalScanned++;
    
    String deviceName = "";
    String deviceAddress = advertisedDevice.getAddress().toString().c_str();
    int rssi = advertisedDevice.getRSSI();
    
    if (advertisedDevice.haveName()) {
      deviceName = advertisedDevice.getName().c_str();
    }
    if (deviceName.length() == 0 && advertisedDevice.haveServiceUUID()) {
      deviceName = "Service Device";
    }
    if (deviceName.length() == 0) {
      deviceName = "Unknown";
    }
    
    if (!matchesFilter(deviceName, deviceAddress)) {
      filteredOut++;
      return;
    }
    
    updateDevice(deviceName, deviceAddress, rssi);
  }
};

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=================================");
  Serial.println("ESP32 BLE Scanner + HiveMQ Cloud");
  Serial.println("NO DISPLAY - Memory Optimized");
  Serial.println("=================================");
  
  pinMode(WIFI_LED_PIN, OUTPUT);
  pinMode(MQTT_LED_PIN, OUTPUT);

  // Build MQTT topics
  snprintf(topic_commands, sizeof(topic_commands), "ble/scanner/%s/commands", device_id);
  snprintf(topic_results, sizeof(topic_results), "ble/scanner/%s/results", device_id);
  snprintf(topic_status, sizeof(topic_status), "ble/scanner/%s/status", device_id);

  // Connect to WiFi FIRST
  Serial.println("\nConnecting to WiFi...");
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    digitalWrite(WIFI_LED_PIN, HIGH);
    Serial.println("\nWiFi connected!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    Serial.print("Free heap after WiFi: ");
    Serial.println(ESP.getFreeHeap());
  } else {
    Serial.println("\nWiFi failed!");
  }

  // Setup and CONNECT to MQTT BEFORE initializing BLE - Core 0 error related
  Serial.println("\nConfiguring MQTT for TLS...");
  espClient.setInsecure();
  espClient.setHandshakeTimeout(30);
  
  mqttClient.setServer(mqtt_server, mqtt_port);
  mqttClient.setCallback(mqttCallback);
  mqttClient.setBufferSize(2048);
  mqttClient.setKeepAlive(60);
  mqttClient.setSocketTimeout(30);

  // Try MQTT connection multiple times before giving up
  Serial.println("Attempting MQTT connection (NO BLE yet)...");
  int mqttAttempts = 0;
  while (!mqttConnected && mqttAttempts < 3) {
    mqttAttempts++;
    Serial.print("Attempt ");
    Serial.print(mqttAttempts);
    Serial.print("/3 - Heap: ");
    Serial.println(ESP.getFreeHeap());
    reconnectMQTT();
    if (!mqttConnected) {
      delay(2000);
    }
  }
  
  if (mqttConnected) {
    Serial.println("MQTT CONNECTED!");
  } else {
    Serial.println("MQTT connection failed - continuing anyway...");
  }

  // Initialize BLE after MQTT is established
  Serial.println("\nNow initializing BLE...");
  Serial.print("Free heap before BLE: ");
  Serial.println(ESP.getFreeHeap());
  
  // Critical: Delay and reduce WiFi power before BLE init
  WiFi.setSleep(true);  // Enable WiFi power saving - again Core 0 error related
  delay(1000);
  
  esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
  bt_cfg.mode = ESP_BT_MODE_BLE;  // BLE only mode - reduce Core usage i guess
  
  if (esp_bt_controller_init(&bt_cfg) != ESP_OK) {
    Serial.println("BT controller init failed");
    return;
  }
  
  if (esp_bt_controller_enable(ESP_BT_MODE_BLE) != ESP_OK) {
    Serial.println("BT controller enable failed");
    return;
  }
  
  BLEDevice::init("");
  pBLEScan = BLEDevice::getScan();
  pBLEScan->setAdvertisedDeviceCallbacks(new MyAdvertisedDeviceCallbacks());
  pBLEScan->setActiveScan(false);
  pBLEScan->setInterval(200);
  pBLEScan->setWindow(100);
  bleActive = true;
  Serial.println("BLE initialized (passive mode)");
  Serial.print("Free heap after BLE: ");
  Serial.println(ESP.getFreeHeap());

  // Initialize devices array
  for (int i = 0; i < MAX_DEVICES; i++) {
    devices[i].active = false;
  }

  Serial.println("\nSetup complete!");
  Serial.print("Free heap: ");
  Serial.println(ESP.getFreeHeap());
  Serial.println("Starting operations...\n");
}

void loop() {
  // Handle MQTT
  if (!mqttClient.connected()) {
    mqttConnected = false;
    digitalWrite(MQTT_LED_PIN, LOW);
    unsigned long now = millis();
    if (now - lastMqttAttempt > mqttRetryInterval) {
      lastMqttAttempt = now;
      reconnectMQTT();
    }
  } else {
    mqttConnected = true;
    digitalWrite(MQTT_LED_PIN, HIGH);
    mqttClient.loop();
  }

  // BLE scanning
  static unsigned long lastScanTime = 0;
  if (bleActive && millis() - lastScanTime >= SCAN_INTERVAL) {
    lastScanTime = millis();
    totalScanned = 0;
    filteredOut = 0;

    BLEScanResults* foundDevices = pBLEScan->start(SCAN_TIME, false);
    Serial.print("Scan: ");
    Serial.print(deviceCount);
    Serial.print(" devices | Total: ");
    Serial.print(totalScanned);
    Serial.print(" | Heap: ");
    Serial.println(ESP.getFreeHeap());
    pBLEScan->clearResults();
  }

  // Check device timeouts
  static unsigned long lastTimeoutCheck = 0;
  if (millis() - lastTimeoutCheck >= 2000) {
    lastTimeoutCheck = millis();
    checkDeviceTimeouts();
  }

  // Publish status every 60 seconds
  static unsigned long lastStatusPublish = 0;
  if (mqttConnected && millis() - lastStatusPublish >= 60000) {
    lastStatusPublish = millis();
    publishStatus();
  }

  // Check WiFi
  static unsigned long lastWiFiCheck = 0;
  if (millis() - lastWiFiCheck >= 30000) {
    lastWiFiCheck = millis();
    if (WiFi.status() != WL_CONNECTED) {
      digitalWrite(WIFI_LED_PIN, LOW);
      WiFi.reconnect();
    } else {
      digitalWrite(WIFI_LED_PIN, HIGH);
    }
  }
}

void reconnectMQTT() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("No WiFi!");
    return;
  }

  String clientId = "ESP32-";
  clientId += String(ESP.getEfuseMac(), HEX);
  
  Serial.print("Free heap: ");
  Serial.print(ESP.getFreeHeap());
  Serial.print(" - Connecting...");
  
  if (mqttClient.connect(clientId.c_str(), mqtt_username, mqtt_password)) {
    digitalWrite(MQTT_LED_PIN, HIGH);
    mqttConnected = true;
    Serial.println("CONNECTED!");
    
    if (mqttClient.subscribe(topic_commands, 1)) {
      Serial.println("Subscribed to commands");
    }
    
    publishStatus();
    
  } else {
    digitalWrite(MQTT_LED_PIN, LOW);
    mqttConnected = false;
    int state = mqttClient.state();
    Serial.print("FAILED: ");
    Serial.println(state);
    
    switch(state) {
      case -4: Serial.println("  TIMEOUT"); break;
      case -3: Serial.println("  CONNECTION LOST"); break;
      case -2: Serial.println("  TLS HANDSHAKE FAILED"); break;
      case 4: Serial.println("  BAD CREDENTIALS"); break;
      case 5: Serial.println("  UNAUTHORIZED"); break;
    }
  }
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message received [");
  Serial.print(topic);
  Serial.print("]: ");
  
  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';
  Serial.println(message);

  JsonDocument doc;
  if (deserializeJson(doc, message)) {
    Serial.println("JSON parsing failed");
    return;
  }

  const char* action = doc["action"];
  const char* requestId = doc["requestId"] | "unknown";

  if (action && strcmp(action, "scan") == 0) {
    Serial.println("Executing SCAN command...");
    performScanAndPublish(String(requestId));
  } else if (action && strcmp(action, "clear") == 0) {
    Serial.println("Executing CLEAR command...");
    clearDevices();
  } else if (action && strcmp(action, "status") == 0) {
    Serial.println("Executing STATUS command...");
    publishStatus();
  }
}

void performScanAndPublish(String requestId) {
  Serial.println("Performing immediate scan for request: " + requestId);

  totalScanned = 0;
  filteredOut = 0;
  BLEScanResults* foundDevices = pBLEScan->start(SCAN_TIME, false);
  pBLEScan->clearResults();

  JsonDocument doc;
  doc["requestId"] = requestId;
  doc["deviceId"] = device_id;
  doc["deviceCount"] = deviceCount;
  doc["totalScanned"] = totalScanned;

  JsonArray devicesArray = doc["devices"].to<JsonArray>();

  for (int i = 0; i < deviceCount; i++) {
    if (devices[i].active) {
      JsonObject device = devicesArray.add<JsonObject>();
      device["name"] = devices[i].name;
      device["address"] = devices[i].address;
      device["rssi"] = devices[i].rssi;
    }
  }

  char jsonBuffer[1024];
  serializeJson(doc, jsonBuffer);
  
  bool published = mqttClient.publish(topic_results, jsonBuffer, false);
  Serial.println(published ? " Results published" : " Publish failed");
}

void publishStatus() {
  JsonDocument doc;
  doc["deviceId"] = device_id;
  doc["status"] = "online";
  doc["uptime"] = millis();
  doc["deviceCount"] = deviceCount;
  doc["freeHeap"] = ESP.getFreeHeap();
  doc["mqttConnected"] = mqttConnected;
  doc["wifiRssi"] = WiFi.RSSI();

  char jsonBuffer[256];
  serializeJson(doc, jsonBuffer);
  
  bool published = mqttClient.publish(topic_status, jsonBuffer, true);
  Serial.println(published ? "Status published" : "Status publish failed");
}

void updateDevice(String name, String address, int rssi) {
  unsigned long currentTime = millis();

  for (int i = 0; i < deviceCount; i++) {
    if (devices[i].address == address) {
      devices[i].lastSeen = currentTime;
      devices[i].rssi = rssi;
      devices[i].active = true;
      if (devices[i].name == "Unknown" && name != "Unknown") {
        devices[i].name = name;
      }
      return;
    }
  }

  if (deviceCount < MAX_DEVICES) {
    devices[deviceCount].name = name;
    devices[deviceCount].address = address;
    devices[deviceCount].rssi = rssi;
    devices[deviceCount].lastSeen = currentTime;
    devices[deviceCount].active = true;
    deviceCount++;
    Serial.print(" NEW: ");
    Serial.print(name);
    Serial.print(" (");
    Serial.print(address);
    Serial.print(") ");
    Serial.println(rssi);
  }
}

void checkDeviceTimeouts() {
  unsigned long currentTime = millis();
  bool devicesChanged = false;

  for (int i = 0; i < deviceCount; i++) {
    if (devices[i].active && (currentTime - devices[i].lastSeen > DEVICE_TIMEOUT)) {
      devices[i].active = false;
      devicesChanged = true;
    }
  }

  if (devicesChanged) {
    int writeIndex = 0;
    for (int readIndex = 0; readIndex < deviceCount; readIndex++) {
      if (devices[readIndex].active) {
        if (writeIndex != readIndex) {
          devices[writeIndex] = devices[readIndex];
        }
        writeIndex++;
      }
    }
    deviceCount = writeIndex;
  }
}

void clearDevices() {
  deviceCount = 0;
  for (int i = 0; i < MAX_DEVICES; i++) {
    devices[i].active = false;
  }
  Serial.println("All devices cleared!");
}

// Add necessary includes at top - can it help? idk to be honest
#include "esp_bt.h"
#include "esp_bt_main.h"